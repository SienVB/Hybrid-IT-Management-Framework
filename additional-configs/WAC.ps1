## Install WAC in High Availability mode

Start-Sleep -s 20

## Download Install-WindowsAdminCenterHA.zip
$url = "https://aka.ms/WACHAScript"
$outpath = "C:\Install-WindowsAdminCenterHA.zip"
Invoke-WebRequest -Uri $url -OutFile $outpath

## Unzip
Expand-Archive -LiteralPath 'C:\Install-WindowsAdminCenterHA.zip' -DestinationPath C:\Scripts

## Download Windows Admin Center .msi
$url = "https://aka.ms/WACDownload"
$outpath = "C:/WindowsAdminCenter.msi"
Invoke-WebRequest -Uri $url -OutFile $outpath

## Create availability cluster
New-Cluster -Name ManagementCluster -Node ManagementVM0.stagesien.com, ManagementVM1.stagesien.com
Set-ClusterQuorum -NoWitness

## Ad cluster disk
Get-ClusterAvailableDisk | Add-ClusterDisk
Add-ClusterSharedVolume -Name "Cluster Disk 1"

## Install WAC in HA mode
C:\Scripts\Install-WindowsAdminCenterHA.ps1 -clusterStorage "C:\ClusterStorage\Volume1" -clientAccessPoint "stagesien-ha-gateway" -msiPath "C:/WindowsAdminCenter.msi" -generateSslCert -Verbose



