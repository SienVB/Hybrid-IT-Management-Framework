## This file contains additional configurations that will be executed on VMs, other code scripts can be found in the documentation and/or other files in this repo


############# Configure On-Prem-DC ###############
$Username = "stagesien\sien"
$SecurePassword = ConvertTo-SecureString "XXXX" -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)

$conn = New-PSSession -ComputerName On-Prem-DC.stagesien.com -Credential (Get-Credential $credentials)

Invoke-Command -Session $conn -ScriptBlock {
## Add UPN suffix for AD tenant
Set-ADForest -Identity stagesien.com -UPNSuffixes @{add="stagesien.onmicrosoft.com"}

## Create new groups
New-ADGroup -Name "Allow_RDP" -GroupCategory Security -GroupScope Global -DisplayName "Allow_RDP" -Path "CN=Users,DC=stagesien,DC=Com" -Description "Members of this group can RDP to client PCs"
New-ADGroup -Name "SSRP" -GroupCategory Security -GroupScope Global -DisplayName "SSRP" -Path "CN=Users,DC=stagesien,DC=Com" -Description "Members of this group have SSRP enabled for them"

## Create new users
New-ADUser -Name test1 -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force) -UserPrincipalName "test1@stagesien.onmicrosoft.com" -Enabled:$True
New-ADUser -Name UserSSRP1 -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force) -UserPrincipalName "UserSSRP1@stagesien.onmicrosoft.com" -Enabled:$True
New-ADUser -Name UserSSRP2 -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force) -UserPrincipalName "UserSSRP2@stagesien.onmicrosoft.com" -Enabled:$True

## Add users to groups
Add-ADGroupMember -Identity "Allow_RDP" -Members "test1"
Add-ADGroupMember -Identity "SSRP" -Members UserSSRP1, UserSSRP2}




############# Configure On-Prem-ADC ###############
$conn = New-PSSession -ComputerName On-Prem-ADC.stagesien.com -Credential (Get-Credential $credentials)

Invoke-Command -Session $conn -ScriptBlock {
## Download AD Connect .msi and save on C drive
$url = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
$outpath = "C:/AzureADC.msi"
Invoke-WebRequest -Uri $url -OutFile $outpath

## Run .msi
Start-Process -Filepath "C:/AzureADC.msi" 

Start-Sleep -s 20

## Import AD sync module
Import-Module "C:\Program Files\Microsoft Azure Active Directory Connect\AdSyncConfig\AdSyncConfig.psm1"  }





############# Configure On-Prem-Client ###############
$conn = New-PSSession -ComputerName On-Prem-Client.stagesien.com -Credential (Get-Credential $credentials)

Invoke-Command -Session $conn -ScriptBlock {
## Add Allow_RDP group to remote desktop users
net localgroup "remote desktop users" /add "Allow_RDP" }





############# Configure ManagementVM0 ###############
$conn = New-PSSession -ComputerName ManagementVM1.stagesien.com -Credential (Get-Credential $credentials)

Invoke-Command -Session $conn -ScriptBlock {
Install-WindowsFeature -Name Failover-Clustering –IncludeManagementTools
Install-windowsFeature RSAT-Clustering -IncludeAllSubFeature -restart}

############# Configure ManagementVM1 ###############
$conn = New-PSSession -ComputerName ManagementVM1.stagesien.com -Credential (Get-Credential $credentials)

Invoke-Command -Session $conn -ScriptBlock {
Install-WindowsFeature -Name Failover-Clustering –IncludeManagementTools
Install-windowsFeature RSAT-Clustering -IncludeAllSubFeature -restart}




############# LAPS ###############

##On On-Prem-DC

##Download LAPSx64.msi and save at On-Prem-DC C:/LAPS/LAPSx54.msi
$url = "https://download.microsoft.com/download/C/7/A/C7AAD914-A8A6-4904-88A1-29E657445D03/LAPS.x64.msi"
$outpath = "C:/LAPS/LAPSx64.msi"
New-Item -Path "c:\LAPS" -Name "LAPS" -ItemType "directory"
Invoke-WebRequest -Uri $url -OutFile $outpath
cd C:/LAPS/
MsiExec.exe /i LAPSx64.msi ADDLOCAL=Management,Management.UI,Management.PS,Management.ADMX ALLUSERS=1 /qn

##Share LAPS folder
New-SmbShare -Name "LAPS" -Path "C:/LAPS"
Grant-SmbShareAccess -Name "LAPS" -AccountName "Everyone" -AccessRight Read -Force

##Raise domain functional level
Set-ADDomainMode –identity stagesien.com -DomainMode Windows2016Domain -Confirm:$false

##Create OU with all computers in
New-ADOrganizationalUnit -Name "Managed Devices" -Path "DC=STAGESIEN,DC=COM"
Move-ADObject –Identity “CN=On-Prem-Client,CN=Computers,DC=stagesien,DC=com” -TargetPath "OU=Managed Devices,DC=stagesien,DC=com"
Move-ADObject –Identity “CN=On-Prem-ADC,CN=Computers,DC=stagesien,DC=com” -TargetPath "OU=Managed Devices,DC=stagesien,DC=com"
Move-ADObject –Identity “CN=ManagementVM0,CN=Computers,DC=stagesien,DC=com” -TargetPath "OU=Managed Devices,DC=stagesien,DC=com"
Move-ADObject –Identity “CN=ManagementVM1,CN=Computers,DC=stagesien,DC=com” -TargetPath "OU=Managed Devices,DC=stagesien,DC=com"


##Import module and update schema
Import-Module AdmPwd.PS
Update-AdmPwdADSchema

##Give computers rights to update password
Set-AdmPwdComputerSelfPermission –Identity "Managed Devices"

##Create new GPO
new-gpo -name LAPS | new-gplink -target "ou=Managed Devices,dc=stagesien,dc=com"




############# AD certficates ###############

##On DC

Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools
Install-AdcsCertificationAuthority -CAType StandaloneRootCa –CACommonName “DC-CA”  -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" -KeyLength 2048 -HashAlgorithmName SHA1 -ValidityPeriod Years -ValidityPeriodUnits 3 -Force
Import-Module ServerManager
Add-WindowsFeature Adcs-Web-Enrollment
Install-AdcsWebEnrollment -CAConfig "DC\DC-CA-1" -Force

##On ManagementVM0
Install-WindowsFeature -name Web-Server -IncludeManagementTools -Confirm:$false


##RBAC
## Create RDP groups
New-ADGroup -Name "Allow_RDP" -GroupCategory Security -GroupScope Global -DisplayName "Allow_RDP" -Path "CN=Users,DC=stagesien,DC=Com" -Description "Members of this group can RDP to the Client VM"
New-ADGroup -Name "RDP_DC" -GroupCategory Security -GroupScope Global -DisplayName "RDP_DC" -Path "CN=Users,DC=stagesien,DC=Com" -Description "Members of this group can RDP to the DCs"
New-ADGroup -Name "RDP_ADC" -GroupCategory Security -GroupScope Global -DisplayName "RDP_ADC" -Path "CN=Users,DC=stagesien,DC=Com" -Description "Members of this group can RDP to the ADC"
New-ADGroup -Name "RDP_Management" -GroupCategory Security -GroupScope Global -DisplayName "RDP_Management" -Path "CN=Users,DC=stagesien,DC=Com" -Description "Members of this group can RDP to the ManagementVMs"

## Create user groups
New-ADGroup -Name "High level admins" -GroupCategory Security -GroupScope Global -DisplayName "High level admins" -Path "CN=Users,DC=stagesien,DC=Com" -Description "Members of this group have have highly privileged abilities"
New-ADGroup -Name "Server Operators" -GroupCategory Security -GroupScope Global 
New-ADGroup -Name "Management" -GroupCategory Security -GroupScope Global -DisplayName "Management" -Path "CN=Users,DC=stagesien,DC=Com" -Description "Members of this group have management privileges"
New-ADGroup -Name "IT" -GroupCategory Security -GroupScope Global -DisplayName "IT" -Path "CN=Users,DC=stagesien,DC=Com" -Description "Members of this group are part of the IT team"
New-ADGroup -Name "Marketing" -GroupCategory Security -GroupScope Global -DisplayName "Marketing" -Path "CN=Users,DC=stagesien,DC=Com" -Description "Members of this group are part of the marketing team"
New-ADGroup -Name "Finance" -GroupCategory Security -GroupScope Global -DisplayName "Finance" -Path "CN=Users,DC=stagesien,DC=Com" -Description "Members of this group are part of the finance team"


## Create new users 
New-ADUser -Name Enterprise-Admin -UserPrincipalName "Enterprise-Admin@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name Domain-Admin  -UserPrincipalName "Domain-Admin@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name DC-Admin -UserPrincipalName "DC-Admin@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name ADC-Admin -UserPrincipalName "ADC-Admin@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name WAC-Admin -UserPrincipalName "WAC-Admin@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name IT-Manager -UserPrincipalName "IT-Manager@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name Finance-Manager -UserPrincipalName "Finance-Manager@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name Marketing-Manager -UserPrincipalName "Marketing-Manager@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name Phil -UserPrincipalName "Phil@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name Claire -UserPrincipalName "Claire@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name Hailey -UserPrincipalName "Hailey@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name Alex -UserPrincipalName "Alex@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name Luke -UserPrincipalName "Luke@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name Cameron -UserPrincipalName "Cameron@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)
New-ADUser -Name Mitchell -UserPrincipalName "Mitchell@stagesien.onmicrosoft.com" -Enabled:$True -Accountpassword (ConvertTo-SecureString "XXXX" -AsPlainText -Force)

## Assign roles to users
Add-ADGroupMember -Identity "Enterprise Admins" -Members sien, Enterprise-Admin
Add-ADGroupMember -Identity "Domain Admins" -Members Domain-Admin
Add-ADGroupMember -Identity "Server Operators" -Members DC-Admin, ADC-Admin, WAC-Admin
Add-ADGroupMember -Identity "Account Operators" -Members IT-Manager, Finance-Manager, Marketing-Manager


## Add users to user groups
Add-ADGroupMember -Identity "High level admins" -Members sien, Enterprise-Admin, Domain-Admin
Add-ADGroupMember -Identity "Management" -Members IT-Manager, Finance-Manager, Marketing-Manager
Add-ADGroupMember -Identity "IT" -Members Phil, Claire, Hailey
Add-ADGroupMember -Identity "Marketing" -Members Alex, Luke
Add-ADGroupMember -Identity "Finance" -Members Cameron, Mitchell

## Add users to RDP groups
Add-ADGroupMember -Identity "Allow_RDP" -Members Phil, Claire, Hailey, Alex, Luke, Cameron, Mitchell
Add-ADGroupMember -Identity "RDP_DC" -Members DC-Admin, sien, Enterprise-Admin, Domain-Admin
Add-ADGroupMember -Identity "RDP_ADC" -Members ADC-Admin, sien, Enterprise-Admin, Domain-Admin
Add-ADGroupMember -Identity "RDP_Management" -Members WAC-Admin, IT-Manager, Marketing-Manager, Finance-Manager

$Username = "stagesien\sien"
$SecurePassword = ConvertTo-SecureString "XXXX" -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)

## On On-Prem-DC
net localgroup "remote desktop users" /add "RDP_DC"
  
## On On-Prem-Client
$conn = New-PSSession -ComputerName On-Prem-Client.stagesien.com -Credential (Get-Credential $credentials)
     
Invoke-Command -Session $conn -ScriptBlock {
net localgroup "remote desktop users" /add "Allow_RDP"
net localgroup "remote desktop users" /add "RDP_DC"
net localgroup "remote desktop users" /add "RDP_ADC"
net localgroup "remote desktop users" /add "RDP_Management"}

##------



## Add RDP groups to remote desktop users groups machines
$Username = "stagesien\sien"
$SecurePassword = ConvertTo-SecureString "XXXX" -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)

## On On-Prem-DC
net localgroup "remote desktop users" /add "RDP_DC"
  
## On On-Prem-Client
$conn = New-PSSession -ComputerName On-Prem-Client.stagesien.com -Credential (Get-Credential $credentials)
     
Invoke-Command -Session $conn -ScriptBlock {
net localgroup "remote desktop users" /add "Allow_RDP"
net localgroup "remote desktop users" /add "RDP_DC"
net localgroup "remote desktop users" /add "RDP_ADC"
net localgroup "remote desktop users" /add "RDP_Management"}

## On DC
$conn = New-PSSession -ComputerName DC.stagesien.com -Credential (Get-Credential $credentials)
     
Invoke-Command -Session $conn -ScriptBlock {
net localgroup "remote desktop users" /add "RDP_DC"}

## On On-Prem-ADC
$conn = New-PSSession -ComputerName On-Prem-ADC.stagesien.com -Credential (Get-Credential $credentials)
     
Invoke-Command -Session $conn -ScriptBlock {
net localgroup "remote desktop users" /add "RDP_ADC"}

## On the ManagementVMs
$conn = New-PSSession -ComputerName ManagementVM0.stagesien.com -Credential (Get-Credential $credentials)
     
Invoke-Command -Session $conn -ScriptBlock {
net localgroup "remote desktop users" /add "RDP_Management"}



