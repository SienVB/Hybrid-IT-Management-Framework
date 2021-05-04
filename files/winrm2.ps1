Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment
$Username = "stagesien\sien"
$SecurePassword = ConvertTo-SecureString "XXXX" -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
Install-ADDSDomainController -InstallDns -Credential (Get-Credential $credentials) -DomainName "stagesien.com" -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText "XXXX" -Force) -Confirm:$false