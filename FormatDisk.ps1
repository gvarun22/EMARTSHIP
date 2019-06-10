# Format managed disk drive and assign drive letter.
function FormatDisk {
    Get-Disk | Where-Object PartitionStyle -eq "RAW" | Initialize-Disk -PartitionStyle MBR -Confirm:$False -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$False
}

# Create working directory and assign local group permissions.
function CreateWorkingDirectoryAndSetPermissions {

    param
    (
        [parameter(Mandatory = $true)]
        [string]$LocalUserGroup,
        [parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    New-LocalGroup $LocalUserGroup
    New-Item -ItemType directory -Path $WorkingDirectory
    
    $Acl = Get-Acl $WorkingDirectory
    $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule($LocalUserGroup, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
    $Acl.AddAccessRule($Rule)
    
    Set-Acl $WorkingDirectory $Acl
}


# Get Access Token to Key vault resource via Managed Identity.
function GetAuthToken {

    param
    (
        [parameter(Mandatory = $true)]
        [string]$KeyVaultName,
        [parameter(Mandatory = $true)]
        [string]$CertName
    )
    
    $KvAuth = Invoke-RestMethod -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' `
        -Method GET -Headers @{ Metadata = 'true' } 

    return $KvAuth
}

# Validate the authentication token.
function ValidateToken {
    
    param
    (
        [parameter(Mandatory = $true)]
        [long]$ExpiresOn
    )

    $Epoc = New-Object -TypeName datetime -ArgumentList @(1970, 1, 1, 0, 0, 0, 0, [DateTimeKind]::Utc)
    $ExpiresOnFull = $epoc.AddSeconds($ExpiresOn)

    if ($ExpiresOnFull -le [DateTime]::UtcNow) {
        Write-Error -Message "The MSI auth token has expired."
        Exit(1)
    }
}

# Return the latest version of the certificate specified.
function GetLatestCert {

    param
    (
        [parameter(Mandatory = $true)]
        [string]$AccessToken,
        [parameter(Mandatory = $true)]
        [string]$KeyVaultName,
        [parameter(Mandatory = $true)]
        [string]$CertName
    )

    $KvApiVer = '2016-10-01'

    $AuthHdr = @{ Authorization = "Bearer $($AccessToken)" }

    # Get the versions of the certificate
    $CertVers = Invoke-RestMethod -UseBasicParsing `
        -Uri "https://$KeyVaultName.vault.azure.net/certificates/$CertName/Versions?api-version=$kvApiVer" `
        -Method GET -Headers $AuthHdr

    # Get the latest certificate version.
    $CertInfo = Invoke-RestMethod -UseBasicParsing `
        -Uri "$($CertVers.value[0].id)?api-version=$($KvApiVer)" `
        -Method GET -Headers $AuthHdr

    # Retrieve the secret value for the cert. This is the pfx.
    $LatestCertSecret = Invoke-RestMethod -UseBasicParsing `
        -Uri "$($CertInfo.sid)?api-version=$($KvApiVer)" `
        -Method GET -Headers $AuthHdr
        
    return $LatestCertSecret
}

# Installs the certificate and perform cleanup afterwards.
function InstallCertAndCleanup {
    param
    (
        [parameter(Mandatory = $true)]
        [string]$LatestCertSecret
    )

    # Write out the PFX data to a temporary file.
    $pfxPath = ".\clusterCert.pfx"

    [Convert]::FromBase64String($LatestCertSecret) | Set-Content -Path $pfxPath -Encoding Byte 

    # Import the pfx into the machine cert store
    Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation 'Cert:\LocalMachine\My\' -Exportable

    # Delete the PFX file
    Remove-Item -Path $pfxPath -Force
}

Write-Host "Format the managed drive."
FormatDisk

$LocalUserGroup = "DataDiskUsers"
$WorkingDirectory = "D:source"

Write-Host "Create working directory and "
CreateWorkingDirectoryAndSetPermissions -LocalUserGroup $LocalUserGroup -WorkingDirectory $WorkingDirectory

$KeyVaultName = "encodingKeyVault"
$CertName = "amsdevsfcluster"

Write-Host "Get key vault Auth token"
$AuthToken = GetAuthToken -KeyVaultName $KeyVaultName -CertName $CertName

Write-Host "Validating token validity"
ValidateToken -ExpiresOn $($AuthToken.expires_on)

Write-Host "Get Latest secret -keyVaultName $KeyVaultName -certName $CertName"
$LatestCertSecret = GetLatestCert -AccessToken $($AuthToken.access_token) -KeyVaultName $KeyVaultName -CertName $CertName

Write-Host "Install cert and clean up"
InstallCertAndCleanup -LatestCertSecret $LatestCertSecret.value
