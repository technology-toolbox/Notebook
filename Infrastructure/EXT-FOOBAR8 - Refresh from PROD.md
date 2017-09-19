# Refresh from PROD

Wednesday, July 5, 2017
8:21 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

```Console
cls
```

## # Prepare environment for refresh from Production

### # Pause Search Service Application

```PowerShell
Enable-SharePointCmdlets

Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

### # Remove old database backups

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Remove-OldBackups.ps1' `
    -NumberOfDaysToKeep 0 `
    -BackupFileExtensions .bak, .trn
```

## # Refresh SecuritasConnect from Production

### # Rebuild SecuritasConnect web application

#### # Backup web.config file

```PowerShell
[Uri] $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

[String] $clientPortalHostHeader = $clientPortalUrl.Host

Copy-Item `
    ("C:\inetpub\wwwroot\wss\VirtualDirectories\$clientPortalHostHeader" `
        + "80\web.config") `
    "C:\NotBackedUp\Temp\Web - $clientPortalHostHeader.config"
```

#### # Delete custom trust relationships

```PowerShell
Get-SPTrustedRootAuthority |
    where { $_.Name -ne 'local' } |
    foreach { Remove-SPTrustedRootAuthority -Identity $_.Name -Confirm:$false }
```

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy SecuritasConnect build from TFS drop location

```PowerShell
$build = "4.0.697.0"

$source = "\\TT-FS01\Builds\Securitas\ClientPortal\$build"
$destination = "\\EXT-FOOBAR8\Builds\ClientPortal\$build"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

#### # Rebuild web application

```PowerShell
$build = "4.0.697.0"

$peoplePickerCredentials = @(
    (Get-Credential "EXTRANET\s-web-client-dev"),
    (Get-Credential "TECHTOOLBOX\svc-sp-ups"))

Push-Location C:\Shares\Builds\ClientPortal\$build\DeploymentFiles\Scripts

& '.\Rebuild Web Application.ps1' `
    -PeoplePickerCredentials $peoplePickerCredentials `
    -Confirm:$false `
    -Verbose

Pop-Location
```

> **Note**
>
> Expect the previous operation to complete in approximately 22 minutes.

#### # Activate "Securitas - Application Settings" feature

```PowerShell
Start-Process $env:SECURITAS_CLIENT_PORTAL_URL/_layouts/15/ManageFeatures.aspx
```

```PowerShell
cls
```

### # Configure SSL on Internet zone

#### # Add public URL for HTTPS

```PowerShell
[Uri] $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

[String] $clientPortalHostHeader = $clientPortalUrl.Host

New-SPAlternateUrl `
    -Url "https://$clientPortalHostHeader" `
    -WebApplication $clientPortalUrl.AbsoluteUri `
    -Zone Internet
```

#### # Add HTTPS binding to site in IIS

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`*.securitasinc.com,*" }

New-WebBinding `
    -Name ("SharePoint - $clientPortalHostHeader" + "80") `
    -Protocol https `
    -Port 443 `
    -HostHeader $clientPortalHostHeader `
    -SslFlags 0
```

### Configure Google Analytics on SecuritasConnect Web application

Tracking ID: **UA-25949832-4**

### Restore SecuritasPortal database backup

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy database backup from Production

```PowerShell
$backupFile = "SecuritasPortal_backup_2017_09_03_000029_3502401.bak"

$source = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destination = "\\EXT-FOOBAR8\Z$\Microsoft SQL Server\MSSQL12.MSSQLSERVER" `
    + "\MSSQL\Backup\Full"

robocopy $source $destination $backupFile
```

---

```PowerShell
cls
```

#### # Stop IIS

```PowerShell
iisreset /stop
```

#### # Restore database backup

```PowerShell
$backupFile = "SecuritasPortal_backup_2017_09_03_000029_3502401.bak"

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH
    REPLACE,
    STATS = 10

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose

Set-Location C:
```

#### # Configure security on SecuritasPortal database

```PowerShell
[Uri] $clientPortalUrl = $null

If ($env:COMPUTERNAME -eq "784816-UATSQL")
{
    $clientPortalUrl = [Uri] "http://client-qa.securitasinc.com"
}
Else
{
    # Development environment is assumed to have SECURITAS_CLIENT_PORTAL_URL
    # environment variable set (since SQL Server is installed on same server as
    # SharePoint)
    $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL
}

[Uri] $employeePortalUrl = [Uri] $clientPortalUrl.AbsoluteUri.Replace(
    "client",
    "employee")

[String] $employeePortalHostHeader = $employeePortalUrl.Host

[String] $farmServiceAccount = "EXTRANET\s-sp-farm-dev"
[String] $clientPortalServiceAccount = "EXTRANET\s-web-client-dev"
[String] $cloudPortalServiceAccount = "EXTRANET\s-web-cloud-dev"
[String[]] $employeePortalAccounts = "IIS APPPOOL\$employeePortalHostHeader"

If ($employeePortalHostHeader -eq "employee-qa.securitasinc.com")
{
    $farmServiceAccount = "SEC\s-sp-farm-qa"
    $clientPortalServiceAccount = "SEC\s-web-client-qa"
    $cloudPortalServiceAccount = "SEC\s-web-cloud-qa"
    $employeePortalAccounts = @(
        'SEC\784813-UATSPAPP$',
        'SEC\784815-UATSPWFE$')
}

[String] $sqlcmd = @"
USE SecuritasPortal
GO

CREATE USER [$farmServiceAccount]
FOR LOGIN [$farmServiceAccount]
GO
ALTER ROLE aspnet_Membership_BasicAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Membership_ReportingAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Roles_BasicAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Roles_ReportingAccess
ADD MEMBER [$farmServiceAccount]
GO

CREATE USER [$clientPortalServiceAccount]
FOR LOGIN [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Membership_FullAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Profile_BasicAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Roles_BasicAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Roles_ReportingAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE Customer_Reader
ADD MEMBER [$clientPortalServiceAccount]
GO

CREATE USER [$cloudPortalServiceAccount]
FOR LOGIN [$cloudPortalServiceAccount]
GO
ALTER ROLE Customer_Provisioner
ADD MEMBER [$cloudPortalServiceAccount]
GO
"@

$employeePortalAccounts |
    foreach {
        $employeePortalAccount = $_

        $sqlcmd += [System.Environment]::NewLine

        $sqlcmd += @"
CREATE USER [$employeePortalAccount]
FOR LOGIN [$employeePortalAccount]
GO
ALTER ROLE Employee_FullAccess
ADD MEMBER [$employeePortalAccount]
GO
"@
    }

$sqlcmd += [System.Environment]::NewLine
$sqlcmd += @"
DROP USER [SEC\258521-VM4$]
DROP USER [SEC\424642-SP$]
DROP USER [SEC\424646-SP$]
DROP USER [SEC\784806-SPWFE1$]
DROP USER [SEC\784807-SPWFE2$]
DROP USER [SEC\784810-SPAPP$]
DROP USER [SEC\s-sp-farm]
DROP USER [SEC\s-web-client]
DROP USER [SEC\s-web-cloud]
DROP USER [SEC\svc-sharepoint-2010]
DROP USER [SEC\svc-web-securitas]
DROP USER [SEC\svc-web-securitas-20]
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose

Set-Location C:
```

#### # Start IIS

```PowerShell
iisreset /start
```

#### # Associate users to TECHTOOLBOX\\smasters

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'TECHTOOLBOX\smasters', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'Jeremy.Jameson@securitasinc.com'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

---

**WOLVERINE**

#### Configure SSO credentials for users

##### Configure TrackTik credentials for Branch Manager

[https://client-local-8.securitasinc.com/_layouts/Securitas/EditProfile.aspx](https://client-local-8.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

Branch Manager: **TECHTOOLBOX\\smasters**\
TrackTik username:** opanduro2m**

##### HACK: Update TrackTik password for Angela.Parks

[https://client-local-8.securitasinc.com/_layouts/Securitas/EditProfile.aspx](https://client-local-8.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

##### HACK: Update TrackTik password for bbarthelemy-demo

[https://client-local-8.securitasinc.com/_layouts/Securitas/EditProfile.aspx](https://client-local-8.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

---

### # Restore content database backups from Production

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy database backups from Production

```PowerShell
$backupFile1 =
    "WSS_Content_SecuritasPortal_backup_2017_09_03_000029_3346241.bak"

$backupFile2 =
    "WSS_Content_SecuritasPortal2_backup_2017_09_03_000029_3502401.bak"

$source = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destination = "\\EXT-FOOBAR8\Z$\Microsoft SQL Server\MSSQL12.MSSQLSERVER" `
    + "\MSSQL\Backup\Full"

robocopy $source $destination $backupFile1 $backupFile2
```

> **Note**
>
> Expect the previous operation to complete in approximately 8-1/2 minutes.

---

#### Export application settings from UAT environment

#### DEV - Copy application settings file from UAT environment

```PowerShell
cls
```

#### # Restore content database backups

##### # Remove existing content databases

```PowerShell
Enable-SharePointCmdlets

Get-SPContentDatabase -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL |
    Remove-SPContentDatabase -Confirm:$false -Force
```

##### # Restore database backups

```PowerShell
$backupFile1 =
    "WSS_Content_SecuritasPortal_backup_2017_09_03_000029_3346241.bak"

$backupFile2 =
    "WSS_Content_SecuritasPortal2_backup_2017_09_03_000029_3502401.bak"

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile1'

RESTORE DATABASE WSS_Content_SecuritasPortal
  FROM DISK = @backupFilePath
  WITH
    STATS = 5

GO

DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile2'

RESTORE DATABASE WSS_Content_SecuritasPortal2
  FROM DISK = @backupFilePath
  WITH
    STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 17 minutes.\
> RESTORE DATABASE successfully processed 3809341 pages in 198.082 seconds (150.243 MB/sec).\
> ...\
> RESTORE DATABASE successfully processed 3738176 pages in 194.225 seconds (150.364 MB/sec).

```PowerShell
cls
```

##### # Attach content databases to web application

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

Mount-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL

Mount-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal2 `
    -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 4 minutes.

```PowerShell
cls
```

### # Configure web application policy for SharePoint administrators

```PowerShell
[Uri] $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

[String] $adminGroup

If ($clientPortalUrl.Host -eq "client-qa.securitasinc.com")
{
    $adminGroup = "SEC\SharePoint Admins (QA)"
}
Else
{
    $adminGroup = "EXTRANET\SharePoint Admins (DEV)"
}

$principal = New-SPClaimsPrincipal -Identity $adminGroup `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication $clientPortalUrl.AbsoluteUri

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $adminGroup)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

### # Import application settings from UAT environment

```PowerShell
Push-Location C:\Shares\Builds\ClientPortal\$build\DeploymentFiles\Scripts

Import-Csv C:\NotBackedUp\Temp\AppSettings-UAT_2017-06-06.csv |
    foreach {
        .\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force -Verbose
    }

Pop-Location
```

### # DEV - Add Branch Managers domain group to Post Orders template sites

```PowerShell
Enable-SharePointCmdlets

$templateSites = @(
    "/Template-Sites/Post-Orders-en-US",
    "/Template-Sites/Post-Orders-en-CA",
    "/Template-Sites/Post-Orders-fr-CA")

$branchManagersClaim = New-SPClaimsPrincipal -Identity "Branch Managers" `
    -IdentityType WindowsSecurityGroupName

$templateSites |
    foreach {
        $siteUrl = $env:SECURITAS_CLIENT_PORTAL_URL + $_

        $site = Get-SPSite $siteUrl

        $group = $site.RootWeb.AssociatedVisitorGroup

        $user = $site.RootWeb.EnsureUser($branchManagersClaim.ToEncodedString())
        $group.AddUser($user)
        $site.Dispose()
    }
```

```PowerShell
cls
```

### # DEV - Replace site collection administrators

```PowerShell
Push-Location C:\Shares\Builds\ClientPortal\$build\DeploymentFiles\Scripts

$claim = New-SPClaimsPrincipal `
    -Identity "EXTRANET\SharePoint Admins (DEV)" `
    -IdentityType WindowsSecurityGroupName

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$tempFileName = [System.Io.Path]::GetTempFileName()
$tempFileName = $tempFileName.Replace(".tmp", ".csv")

Get-SPSite -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL -Limit ALL |
    select Url |
    Export-Csv -Path $tempFileName -Encoding UTF8 -NoTypeInformation

Import-Csv $tempFileName |
    select -ExpandProperty Url |
    C:\NotBackedUp\Public\Toolbox\PowerShell\Run-CommandMultiThreaded.ps1 `
        -Command '.\Set-SiteAdministrator.ps1' `
        -AddParam @{"Claim" = $claim} `
        -SnapIns 'Microsoft.SharePoint.PowerShell'

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch

Pop-Location
```

> **Note**
>
> Expect the previous operation to complete in approximately 56 minutes.

```PowerShell
cls
```

## # Refresh C&C from Production

### # Rebuild C&C web application

#### # Backup web.config file

```PowerShell
[Uri] $cloudPortalUrl = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

[String] $cloudPortalHostHeader = $cloudPortalUrl.Host

Copy-Item `
    ("C:\inetpub\wwwroot\wss\VirtualDirectories\$cloudPortalHostHeader" `
        + "80\web.config") `
    "C:\NotBackedUp\Temp\Web - $cloudPortalHostHeader.config"
```

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy C&C build from TFS drop location

```PowerShell
$build = "2.0.125.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\CloudPortal\$build"
$destPath = "\\EXT-FOOBAR2\Builds\CloudPortal\$build"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

#### # Rebuild web application

```PowerShell
$build = "2.0.125.0"

$peoplePickerCredentials = @(
    (Get-Credential "EXTRANET\s-web-cloud-dev"),
    (Get-Credential "TECHTOOLBOX\svc-sp-ups"),
    (Get-Credential "FABRIKAM\s-sp-ups"))

Push-Location C:\Shares\Builds\CloudPortal\$build\DeploymentFiles\Scripts

& '.\Rebuild Web Application.ps1' `
    -PeoplePickerCredentials $peoplePickerCredentials `
    -Confirm:$false `
    -Verbose

Pop-Location
```

> **Note**
>
> Expect the previous operation to complete in approximately 8 minutes.

```PowerShell
cls
```

### # Configure SSL on Internet zone

#### # Add public URL for HTTPS

```PowerShell
[Uri] $cloudPortalUrl = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

[String] $cloudPortalHostHeader = $cloudPortalUrl.Host

New-SPAlternateUrl `
    -Url "https://$cloudPortalHostHeader" `
    -WebApplication $cloudPortalUrl.AbsoluteUri `
    -Zone Internet
```

#### # Add HTTPS binding to site in IIS

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`*.securitasinc.com,*" }

New-WebBinding `
    -Name ("SharePoint - $cloudPortalHostHeader" + "80") `
    -Protocol https `
    -Port 443 `
    -HostHeader $cloudPortalHostHeader `
    -SslFlags 0
```

#### Configure Google Analytics on Cloud Portal Web application

Tracking ID: **UA-25949832-5**

### Restore content database backup from Production

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy database backup from Production

```PowerShell
$backupFile = "WSS_Content_CloudPortal_backup_2017_09_03_000029_3502401.bak"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destPath = "\\EXT-FOOBAR2\Z$\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL" `
    + "\Backup\Full"

robocopy $sourcePath $destPath $backupFile
```

> **Note**
>
> Expect the previous operation to complete in approximately 20 minutes.

---

```PowerShell
cls
```

#### # Restore content database backup

##### # Remove existing content database

```PowerShell
Enable-SharePointCmdlets

Get-SPContentDatabase -WebApplication $env:SECURITAS_CLOUD_PORTAL_URL |
    Remove-SPContentDatabase -Confirm:$false -Force
```

##### # Restore database backup

```PowerShell
$backupFile = "WSS_Content_CloudPortal_backup_2017_09_03_000029_3502401.bak"

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

RESTORE DATABASE WSS_Content_CloudPortal
  FROM DISK = @backupFilePath
  WITH
    STATS = 5

GO
```

"@

```PowerShell
Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 48 minutes.\
> RESTORE DATABASE successfully processed 8944387 pages in 2361.866 seconds (29.585 MB/sec).

```PowerShell
cls
```

##### # Attach content database

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

Mount-SPContentDatabase `
    -Name WSS_Content_CloudPortal `
    -WebApplication $env:SECURITAS_CLOUD_PORTAL_URL

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 4 seconds.

```PowerShell
cls
```

### # Configure web application policy for SharePoint administrators group

```PowerShell
[Uri] $cloudPortalUrl = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

[String] $adminGroup

If ($clientPortalUrl.Host -eq "cloud-qa.securitasinc.com")
{
    $adminGroup = "SEC\SharePoint Admins (QA)"
}
Else
{
    $adminGroup = "EXTRANET\SharePoint Admins (DEV)"
}

$principal = New-SPClaimsPrincipal -Identity $adminGroup `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication $cloudPortalUrl.AbsoluteUri

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $adminGroup)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

## # Backup databases and perform full crawl

### # Backup databases

#### # Remove obsolete database backups

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Remove-OldBackups.ps1' `
    -NumberOfDaysToKeep 0 `
    -BackupFileExtensions .bak, .trn
```

#### # Backup all databases

```PowerShell
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") |
    Out-Null

$sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server

$job = ($sqlServer.JobServer.Jobs |
    where { $_.Name -eq "Full Backup of All Databases.Subplan_1" })

$job.Start()

Start-Sleep -Seconds 30

Write-Host "Waiting for backup job to complete..."

while ($job.CurrentRunStatus -eq "Executing") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 10

    $sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server

    $job = ($sqlServer.JobServer.Jobs |
        where { $_.Name -eq "Full Backup of All Databases.Subplan_1" })
}

Write-Host
```

### # Reset search index and perform full crawl

```PowerShell
Enable-SharePointCmdlets

$serviceApp = Get-SPEnterpriseSearchServiceApplication
```

#### # Resume Search Service Application

```PowerShell
Resume-SPEnterpriseSearchServiceApplication -Identity $serviceApp
```

#### # Reset search index

```PowerShell
$serviceApp.Reset($false, $false)
```

#### # Start full crawl

```PowerShell
$serviceApp |
    Get-SPEnterpriseSearchCrawlContentSource |
    foreach { $_.StartFullCrawl() }
```

> **Note**
>
> Expect the crawl to complete in approximately 7 hours.
