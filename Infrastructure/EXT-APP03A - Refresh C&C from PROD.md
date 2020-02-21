#

Tuesday, March 27, 2018
9:33 AM

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
$build = "2.0.131.0"

$source = "\\TT-FS01\Builds\Securitas\CloudPortal\$build"
$destination = "\\EXT-APP02A.extranet.technologytoolbox.com\Builds" `
    + "\CloudPortal\$build"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

#### # Rebuild web application

```PowerShell
$build = "2.0.131.0"

$peoplePickerCredentials = @(
    (Get-Credential "EXTRANET\s-web-cloud"),
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

---

**EXT-WEB02A**

```PowerShell
cls
```

#### # Add HTTPS binding to site in IIS

```PowerShell
[String] $cloudPortalHostHeader = "cloud-test.securitasinc.com"

$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`*.securitasinc.com,*" }

New-WebBinding `
    -Name ("SharePoint - $cloudPortalHostHeader" + "80") `
    -Protocol https `
    -Port 443 `
    -HostHeader $cloudPortalHostHeader `
    -SslFlags 0
```

---

---

**EXT-WEB02B**

```PowerShell
cls
```

#### # Add HTTPS binding to site in IIS

```PowerShell
[String] $cloudPortalHostHeader = "cloud-test.securitasinc.com"

$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`*.securitasinc.com,*" }

New-WebBinding `
    -Name ("SharePoint - $cloudPortalHostHeader" + "80") `
    -Protocol https `
    -Port 443 `
    -HostHeader $cloudPortalHostHeader `
    -SslFlags 0
```

---

#### Configure Google Analytics on Cloud Portal Web application

Tracking ID: **UA-25899478-3**

### Restore content database backup from Production

---

**TT-FS01**

```PowerShell
cls
```

#### # Copy database backup from Production

```PowerShell
$backupFile = "WSS_Content_CloudPortal_backup_2018_02_13_053955_4464040.bak"

$source = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destination = "\\EXT-SQL02.extranet.technologytoolbox.com\Z$" `
    + "\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

robocopy $source $destination $backupFile
```

> **Note**
>
> Expect the previous operation to complete in approximately 29 minutes.

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

---

**EXT-SQL02**

```PowerShell
cls
```

##### # Restore database backup

```PowerShell
$backupFile = "WSS_Content_CloudPortal_backup_2018_02_13_053955_4464040.bak"

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
> Expect the previous operation to complete in approximately 1 hour and 29 minutes.\
> RESTORE DATABASE successfully processed 10013905 pages in 4178.661 seconds (18.722 MB/sec).

---

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
> Expect the previous operation to complete in approximately 15 seconds.

```PowerShell
cls
```

### # Configure web application policy for SharePoint administrators group

```PowerShell
[Uri] $cloudPortalUrl = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

[String] $adminGroup

If ($cloudPortalUrl.Host -eq "cloud-qa.securitasinc.com")
{
    $adminGroup = "SEC\SharePoint Admins (QA)"
}
ElseIf ($cloudPortalUrl.Host -eq "cloud-test.securitasinc.com")
{
    $adminGroup = "EXTRANET\SharePoint Admins"
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

```PowerShell
cls
```

### # Replace permissions for "Domain Users" on Cloud Portal sites

```PowerShell
[Uri] $cloudPortalUrl = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

Get-SPSite -WebApplication $cloudPortalUrl.AbsoluteUri -Limit All |
    foreach {
        $site = $_

        $site.RootWeb.Groups |
            foreach {
                $group = $_

                $group.Users |
                    foreach {
                        $user = $_

                        If ($user.DisplayName -eq "PNKCAN\Domain Users")
                        {
                            Write-Host ("Replacing group ($($user.DisplayName))" `
                                + " on site ($($site.Url))...")

                            $fabrikamUsers = New-SPClaimsPrincipal `
                                -Identity "FABRIKAM\Domain Users" `
                                -IdentityType WindowsSecurityGroupName

                            $group.AddUser(
                                $fabrikamUsers.ToEncodedString(),
                                $null,
                                "FABRIKAM\Domain Users",
                                $null)

                            $group.Users.Remove($user)
                        }
                        ElseIf ($user.DisplayName -eq "PNKUS\Domain Users")
                        {
                            Write-Host ("Replacing group ($($user.DisplayName))" `
                                + " on site ($($site.Url))...")

                            $techtoolboxUsers = New-SPClaimsPrincipal `
                                -Identity "TECHTOOLBOX\Domain Users" `
                                -IdentityType WindowsSecurityGroupName

                            $group.AddUser(
                                $techtoolboxUsers.ToEncodedString(),
                                $null,
                                "TECHTOOLBOX\Domain Users",
                                $null)

                            $group.Users.Remove($user)
                        }
                    }
            }

        $site.Dispose()
    }
```

```PowerShell
cls
```

### # Configure custom sign-in page on Web application

```PowerShell
Set-SPWebApplication `
    -Identity $env:SECURITAS_CLOUD_PORTAL_URL `
    -Zone Default `
    -SignInRedirectURL "/Pages/Sign-In.aspx"
```

```PowerShell
cls
```

### # Extend web application to Intranet zone

```PowerShell
$intranetHostHeader = $cloudPortalUrl.Host -replace "cloud", "cloud2"

$webApp = Get-SPWebApplication -Identity $cloudPortalUrl.AbsoluteUri

$windowsAuthProvider = New-SPAuthenticationProvider

$webAppName = "SharePoint - " + $intranetHostHeader + "443"

$webApp | New-SPWebApplicationExtension `
    -Name $webAppName `
    -Zone Intranet `
    -AuthenticationProvider $windowsAuthProvider `
    -HostHeader $intranetHostHeader `
    -Port 443 `
    -SecureSocketsLayer
```

## Backup databases and perform full crawl

---

**EXT-SQL02**

```PowerShell
cls
```

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

---

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
