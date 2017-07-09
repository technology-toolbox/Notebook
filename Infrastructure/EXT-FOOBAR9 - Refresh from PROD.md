# Refresh from PROD

Wednesday, July 5, 2017
8:21 AM

```PowerShell
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
    ForEach-Object { Remove-SPTrustedRootAuthority -Identity $_.Name -Confirm:$false }
```

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy SecuritasConnect build from TFS drop location

```PowerShell
$build = "4.0.681.1"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$build"
$destPath = "\\EXT-FOOBAR8\Builds\ClientPortal\$build"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

#### # Rebuild web application

```PowerShell
$build = "4.0.681.1"

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
$backupFile = "SecuritasPortal_backup_2017_07_02_000024_5389272.bak"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destPath = "\\EXT-FOOBAR8\Z$\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL" `
    + "\Backup\Full"

robocopy $sourcePath $destPath $backupFile
```

---

```PowerShell
cls
```

#### # Restore database backup

```PowerShell
$backupFile = "SecuritasPortal_backup_2017_07_02_000024_5389272.bak"

iisreset /stop

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal_log.LDF'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH
    MOVE 'SecuritasPortal' TO @dataFilePath,
    MOVE 'SecuritasPortal_log' TO @logFilePath,
    REPLACE,
    STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Configure permissions for SecuritasPortal database

```PowerShell
[Uri] $employeePortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "employee")

[String] $employeePortalHostHeader = $employeePortalUrl.Host

$sqlcmd = @"
USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO

CREATE USER [EXTRANET\s-web-client-dev] FOR LOGIN [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\s-web-client-dev]
GO

CREATE USER [IIS APPPOOL\$employeePortalHostHeader]
FOR LOGIN [IIS APPPOOL\$employeePortalHostHeader]
GO
EXEC sp_addrolemember N'Employee_FullAccess',
    N'IIS APPPOOL\$employeePortalHostHeader'

GO

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

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

iisreset /start
```

### # Restore content database backups from Production

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy database backups from Production

```PowerShell
$backupFile1 = "WSS_Content_SecuritasPortal_backup_2017_07_02_000024_5233019.bak"
$backupFile2 = "WSS_Content_SecuritasPortal2_backup_2017_07_02_000024_5389272.bak"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destPath = "\\EXT-FOOBAR8\Z$\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL" `
    + "\Backup\Full"

robocopy $sourcePath $destPath $backupFile1 $backupFile2
```

> **Note**
>
> Expect the previous operation to complete in approximately 9 minutes.

---

```PowerShell
cls
```

#### # Restore content database backups

##### # Remove existing content databases

```PowerShell
Remove-SPContentDatabase WSS_Content_SecuritasPortal -Confirm:$false -Force
```

##### # Restore database backups

```PowerShell
$backupFile1 = "WSS_Content_SecuritasPortal_backup_2017_07_02_000024_5233019.bak"
$backupFile2 = "WSS_Content_SecuritasPortal2_backup_2017_07_02_000024_5389272.bak"

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile1'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal_log.LDF'

RESTORE DATABASE WSS_Content_SecuritasPortal
  FROM DISK = @backupFilePath
  WITH
    MOVE 'WSS_Content_SecuritasPortal' TO @dataFilePath,
    MOVE 'WSS_Content_SecuritasPortal_log' TO @logFilePath,
    STATS = 5

GO

DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile2'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal2.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal2_log.LDF'

RESTORE DATABASE WSS_Content_SecuritasPortal2
  FROM DISK = @backupFilePath
  WITH
    MOVE 'WSS_Content_SecuritasPortal2' TO @dataFilePath,
    MOVE 'WSS_Content_SecuritasPortal2_log' TO @logFilePath,
    STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 45 minutes.\
> RESTORE DATABASE successfully processed 3885930 pages in 1297.310 seconds (23.401 MB/sec).\
> ...\
> RESTORE DATABASE successfully processed 3701385 pages in 1214.998 seconds (23.800 MB/sec).

```PowerShell
cls
```

##### # Attach content databases

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
> Expect the previous operation to complete in approximately 7 minutes.

```PowerShell
cls
```

### # Configure Web application policy for SharePoint administrators group

```PowerShell
$webAppUrl = $env:SECURITAS_CLIENT_PORTAL_URL
$adminsGroup = "EXTRANET\SharePoint Admins (DEV)"

$principal = New-SPClaimsPrincipal -Identity $adminsGroup `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication $webAppUrl

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $adminsGroup)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

### # Restore application settings from UAT

```PowerShell
Push-Location C:\Shares\Builds\ClientPortal\$build\DeploymentFiles\Scripts

Import-Csv "C:\NotBackedUp\Temp\AppSettings-UAT_2017-06-06.csv" |
    ForEach-Object {
        .\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force -Verbose
    }

Pop-Location
```

### # Add Branch Managers domain group to Post Orders template site

```PowerShell
Enable-SharePointCmdlets

@("$env:SECURITAS_CLIENT_PORTAL_URL/Template-Sites/Post-Orders-en-US",
    "$env:SECURITAS_CLIENT_PORTAL_URL/Template-Sites/Post-Orders-en-CA",
    "$env:SECURITAS_CLIENT_PORTAL_URL/Template-Sites/Post-Orders-fr-CA") |
    ForEach-Object {
        $siteUrl = $_

        $site = Get-SPSite $siteUrl

        $group = $site.RootWeb.AssociatedVisitorGroup

        $claim = New-SPClaimsPrincipal -Identity "Branch Managers" `
            -IdentityType WindowsSecurityGroupName

        $branchManagersUser = $site.RootWeb.EnsureUser($claim.ToEncodedString())
        $group.AddUser($branchManagersUser)
        $site.Dispose()
    }
```

### # Replace site collection administrators

---

**C:\\NotBackedUp\\Temp\\Replace Site Collection Administrators.ps1**

```PowerShell
param(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String] $Url,
    [String] $AdminUserOrGroup = "EXTRANET\SharePoint Admins (DEV)"
)

begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    If ((Get-PSSnapin Microsoft.SharePoint.PowerShell `
        -ErrorAction SilentlyContinue) -eq $null)
    {
        Write-Debug "Adding snapin (Microsoft.SharePoint.PowerShell)..."

        $ver = $host | select version

        #If ($ver.Version.Major -gt 1)
        #{
        #    $Host.Runspace.ThreadOptions = "ReuseThread"
        #}

        Add-PSSnapin Microsoft.SharePoint.PowerShell
    }

    Function ReplaceSiteCollectionAdministrators(
        $site,
        $newAdminUserOrGroup)
    {
        Write-Verbose `
            "Replacing site collection administrators on site ($($site.Url))..."

        For ($i = 0; $i -lt $site.RootWeb.SiteAdministrators.Count; $i++)
        {
            $siteAdmin = $site.RootWeb.SiteAdministrators[$i]

            Write-Debug "siteAdmin: $($siteAdmin.LoginName)"

            If ($siteAdmin.DisplayName -eq "SEC\SharePoint Admins")
            {
                Write-Verbose "Removing administrator ($($siteAdmin.DisplayName))..."
                $site.RootWeb.SiteAdministrators.Remove($i)
                $i--
            }
        }

        Write-Debug `
            "Adding SharePoint Admins on site ($($site.Url))..."

        $user = $site.RootWeb.EnsureUser($newAdminUserOrGroup)
        $user.IsSiteAdmin = $true
        $user.Update()

        $output = New-Object PSObject

        $output | Add-Member NoteProperty -Name "Url" `
            -Value $site.Url

        $output | Add-Member NoteProperty -Name "Admin" `
            -Value $newAdminUserOrGroup

        $output
    }
}

process
{
    $site = Get-SPSite -Identity $Url

    Try
    {
        Write-Verbose "Processing site ($($site.Url))..."

        ReplaceSiteCollectionAdministrators $site $AdminUserOrGroup
    }
    Finally
    {
        $site.Dispose()
    }
}
```

---

```PowerShell
cls
Push-Location C:\NotBackedUp\Temp

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$tempFileName = [System.Io.Path]::GetTempFileName()
$tempFileName = $tempFileName.Replace(".tmp", ".csv")

Get-SPSite -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL -Limit ALL |
    select Url |
    Export-Csv -Path $tempFileName -Encoding UTF8 -NoTypeInformation

Import-Csv $tempFileName |
    select -ExpandProperty Url |
    C:\NotBackedUp\Public\Toolbox\PowerShell\Run-CommandMultiThreaded.ps1 `
        -Command '.\Replace Site Collection Administrators.ps1' `
        -SnapIns 'Microsoft.SharePoint.PowerShell'

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch

Pop-Location
```

> **Note**
>
> Expect the previous operation to complete in approximately 58 minutes.

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
$build = "2.0.122.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\CloudPortal\$build"
$destPath = "\\EXT-FOOBAR8\Builds\CloudPortal\$build"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

#### # Rebuild web application

```PowerShell
$build = "2.0.122.0"

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

#### # Copy database backups from Production

```PowerShell
$backupFile = "WSS_Content_CloudPortal_backup_2017_07_02_000024_5545517.bak"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destPath = "\\EXT-FOOBAR8\Z$\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL" `
    + "\Backup\Full"

robocopy $sourcePath $destPath $backupFile
```

> **Note**
>
> Expect the previous operation to complete in approximately 27 minutes.

---

```PowerShell
cls
```

#### # Restore content database backup

##### # Remove existing content database

```PowerShell
Remove-SPContentDatabase WSS_Content_CloudPortal -Confirm:$false -Force
```

##### # Restore database backup

```PowerShell
$backupFile = "WSS_Content_CloudPortal_backup_2017_07_02_000024_5545517.bak"

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_CloudPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_CloudPortal_log.LDF'

RESTORE DATABASE WSS_Content_CloudPortal
  FROM DISK = @backupFilePath
  WITH
    MOVE 'WSS_Content_CloudPortal' TO @dataFilePath,
    MOVE 'WSS_Content_CloudPortal_log' TO @logFilePath,
    STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 53 minutes.\
> RESTORE DATABASE successfully processed 8924381 pages in 2901.476 seconds (24.029 MB/sec).

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
> Expect the previous operation to complete in approximately 10 seconds.

```PowerShell
cls
```

### # Configure Web application policy for SharePoint administrators group

```PowerShell
$webAppUrl = $env:SECURITAS_CLOUD_PORTAL_URL
$adminsGroup = "EXTRANET\SharePoint Admins (DEV)"

$principal = New-SPClaimsPrincipal -Identity $adminsGroup `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication $webAppUrl

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $adminsGroup)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

## # Backup databases

### # Remove old database backups

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Remove-OldBackups.ps1' `
    -NumberOfDaysToKeep 0 `
    -BackupFileExtensions .bak, .trn
```

### # Backup all databases

```PowerShell
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") |
    Out-Null

$sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server $HostName

$job = ($sqlServer.JobServer.Jobs |
    ? { $_.Name -eq "Full Backup of All Databases.Subplan_1" })

$job.Start()

Start-Sleep -Seconds 30

Write-Host "Waiting for backup job to complete..."

while ($job.CurrentRunStatus -eq "Executing") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 10

    $sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server $HostName

    $job = ($sqlServer.JobServer.Jobs |
        ? { $_.Name -eq "Full Backup of All Databases.Subplan_1" })
}

Write-Host
```

## # Reset search index and perform full crawl

```PowerShell
Enable-SharePointCmdlets

$serviceApp = Get-SPEnterpriseSearchServiceApplication
```

### # Reset search index

```PowerShell
$serviceApp.Reset($false, $false)
```

### # Start full crawl

```PowerShell
$serviceApp |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
```

> **Note**
>
> Expect the crawl to complete in approximately 8 hours 28 minutes.
