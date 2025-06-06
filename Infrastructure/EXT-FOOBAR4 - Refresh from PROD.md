# Refresh from PROD

Wednesday, July 5, 2017\
8:21 AM

## Restore SecuritasPortal database backup

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Copy database backup from Production

```PowerShell
$backupFile = "SecuritasPortal_backup_2018_05_27_000026_2324733.bak"
$computerName = "EXT-FOOBAR4"

$source = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destination = "\\$computerName\Z`$\Microsoft SQL Server\MSSQL12.MSSQLSERVER" `
    + "\MSSQL\Backup\Full"

robocopy $source $destination $backupFile
```

---

```PowerShell
cls
```

### # Stop IIS

```PowerShell
iisreset /stop
```

### # Restore database backup

```PowerShell
$backupFile = "SecuritasPortal_backup_2018_05_27_000026_2324733.bak"

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

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

### # Configure security on SecuritasPortal database

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

[Uri] $idpUrl = [Uri] `
    $env:SECURITAS_CLIENT_PORTAL_URL.Replace("client", "idp").Replace( `
        "securitasinc.com", "technologytoolbox.com")

[String] $idpHostHeader = $idpUrl.Host

[String] $farmServiceAccount = "EXTRANET\s-sp-farm-dev"
[String] $clientPortalServiceAccount = "EXTRANET\s-web-client-dev"
[String] $cloudPortalServiceAccount = "EXTRANET\s-web-cloud-dev"
[String[]] $employeePortalAccounts = "IIS APPPOOL\$employeePortalHostHeader"
[String[]] $idpServiceAccounts = "IIS APPPOOL\$idpHostHeader"

If ($employeePortalHostHeader -eq "employee-qa.securitasinc.com")
{
    $farmServiceAccount = "SEC\s-sp-farm-qa"
    $clientPortalServiceAccount = "SEC\s-web-client-qa"
    $cloudPortalServiceAccount = "SEC\s-web-cloud-qa"
    $employeePortalAccounts = @(
        'SEC\784813-UATSPAPP$',
        'SEC\784815-UATSPWFE$')

    $idpServiceAccounts = $employeePortalAccounts
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

$idpServiceAccounts |
    foreach {
        $idpServiceAccount = $_

        $sqlcmd += [System.Environment]::NewLine

        $sqlcmd += @"
CREATE USER [$idpServiceAccount]
FOR LOGIN [$idpServiceAccount]
GO
ALTER ROLE aspnet_Membership_BasicAccess
ADD MEMBER [$idpServiceAccount]

ALTER ROLE aspnet_Membership_ReportingAccess
ADD MEMBER [$idpServiceAccount]

ALTER ROLE aspnet_Roles_BasicAccess
ADD MEMBER [$idpServiceAccount]

ALTER ROLE aspnet_Roles_ReportingAccess
ADD MEMBER [$idpServiceAccount]
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

### # Associate users to TECHTOOLBOX\\jjameson

```PowerShell
$sqlcmd = @"
USE SecuritasPortal
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'jjameson@technologytoolbox.com', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'Jeremy.Jameson@securitasinc.com'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

### # Replace shortcuts for PNKUS\\jjameson

```PowerShell
$sqlcmd = @"
USE SecuritasPortal
GO

UPDATE Employee.PortalUsers
SET UserName = 'TECHTOOLBOX\jjameson'
WHERE UserName = 'PNKUS\jjameson'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

### # Issue - Owner is not set on database after restore (e.g. cannot create database diagrams)

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

EXEC dbo.sp_changedbowner @loginame = N'sa', @map = false
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

### # Associate users to TECHTOOLBOX\\smasters

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'smasters@technologytoolbox.com', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'Jeremy.Jameson@securitasinc.com'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

### # Start IIS

```PowerShell
iisreset /start
```

---

**WOLVERINE** - Run as administrator

### Configure SSO credentials for users

#### Configure TrackTik credentials for Branch Manager

[https://client-local-4.securitasinc.com/\_layouts/Securitas/EditProfile.aspx](https://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

Branch Manager: **smasters@technologytoolbox.com**\
TrackTik username:** opanduro2m**

#### HACK: Update TrackTik password for Angela.Parks

[https://client-local-4.securitasinc.com/\_layouts/Securitas/EditProfile.aspx](https://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

#### HACK: Update TrackTik password for bbarthelemy-demo

[https://client-local-4.securitasinc.com/\_layouts/Securitas/EditProfile.aspx](https://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

---
