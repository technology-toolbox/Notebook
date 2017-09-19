# Refresh from PROD

Wednesday, July 5, 2017
8:21 AM

## Restore SecuritasPortal database backup

---

**784811-SQL1**

```PowerShell
cls
```

### # Create copy-only database backup

```PowerShell
$sqlcmd = @"
DECLARE @databaseName VARCHAR(50) = 'SecuritasPortal'

DECLARE @backupDirectory VARCHAR(255)

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @backupDirectory OUTPUT

DECLARE @backupFilePath VARCHAR(255) =
    @backupDirectory + '\Full\' + @databaseName + '.bak'

DECLARE @backupName VARCHAR(100) = @databaseName + '-Full Database Backup'

BACKUP DATABASE @databaseName
    TO DISK = @backupFilePath
    WITH COMPRESSION
        , COPY_ONLY
        , INIT
        , NAME = @backupName
        , STATS = 10

GO
"@

Invoke-Sqlcmd `
    -Query $sqlcmd `
    -QueryTimeout 0 `
    -ServerInstance 784837-SQLCLUS1 `
    -Verbose `
    -Debug:$false

Set-Location C:
```

---

---

**WOLVERINE**

```PowerShell
cls
```

### # Copy database backup from Production

```PowerShell
$backupFile = "SecuritasPortal.bak"

$source = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destination = "\\EXT-FOOBAR9\Z$\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL" `
    + "\Backup\Full"

robocopy $source $destination $backupFile
```

---

```PowerShell
cls
```

### # Restore database backup

```PowerShell
$backupFile = "SecuritasPortal.bak"

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

### # Configure permissions for SecuritasPortal database

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

---

**WOLVERINE**

### Configure TrackTik credentials for Branch Manager

[https://client-local-9.securitasinc.com/_layouts/Securitas/EditProfile.aspx](https://client-local-9.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

Branch Manager: **TECHTOOLBOX\\smasters**\
TrackTik username:** opanduro2m**

### HACK: Update TrackTik password for Angela.Parks

[https://client-local-9.securitasinc.com/_layouts/Securitas/EditProfile.aspx](https://client-local-9.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

### HACK: Update TrackTik password for bbarthelemy-demo

[https://client-local-9.securitasinc.com/_layouts/Securitas/EditProfile.aspx](https://client-local-9.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

---
