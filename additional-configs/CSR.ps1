Write-Host "Creating CertificateRequest(CSR) for $CertName `r "
 
Invoke-Command -ComputerName DC.stagesiencom -ScriptBlock {
  
$CertName = "DC.stagesien.com"
$CSRPath = "c:\$($CertName).csr"
$INFPath = "c:\$($CertName).inf"
$Signature = '$Windows NT$' 
 
 
$INF =
@"
[Version]
Signature= "$Signature" 
 
[NewRequest]
Subject = "CN=$CertName"
KeyLength = 2048
Exportable = TRUE
MachineKeySet = TRUE
SMIME = False
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0
 
[EnhancedKeyUsageExtension]
 
OID=1.3.6.1.5.5.7.3.1 
"@
 
write-Host "Certificate Request is being generated `r "
$INF | out-file -filepath $INFPath -force
certreq -new $INFPath $CSRPath
 
}

write-output "Certificate Request has been generated"