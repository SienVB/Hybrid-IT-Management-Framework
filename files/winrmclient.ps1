## Add ADC VM to domain
$Username = "stagesien\sien"
$SecurePassword = ConvertTo-SecureString "6?3Wkv7mAk]aOsdR" -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
Add-Computer -Credential (Get-Credential $credentials) -DomainName stagesien.com -Restart -Confirm:$false
