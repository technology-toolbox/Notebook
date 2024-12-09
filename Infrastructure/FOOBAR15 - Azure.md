# FOOBAR15 - Azure

Wednesday, February 25, 2015\
6:16 AM

Standard A4 VM - 8 CPU, 14 GB

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/0EBCD9008812784FF8402D22E5FFB4684034EFDA.png)

Page file on D: (DAS)

```Text
PS C:\ConfigureDeveloperDesktop\Scripts> .\ConfigureSharePointFarm.ps1

cmdlet ConfigureSharePointFarm.ps1 at command pipeline position 1
Supply values for the following parameters:
localSPFarmAccountName: SP_Farm
localSPFarmAccountPassword: {password}
(VM) 02/25/2015 12:43:07: Start to configure SharePoint Farm account.
(VM) 02/25/2015 12:43:08: Start to configure SQL Server.
(VM) 02/25/2015 12:53:03: SQL Server has been configured successfully.
The local farm is not accessible. Cmdlets with FeatureDependencyId are not registered.
(VM) 02/25/2015 12:53:24: Start to create the configuration database SP2013_Configuration.
(VM) 02/25/2015 13:06:08: SharePoint Farm is now running.
(VM) 02/25/2015 13:06:08: Start to create the Central Administration site on port 11111.
(VM) 02/25/2015 13:08:01: Start to install help collections.
(VM) 02/25/2015 13:08:01: Start to initialize security.
(VM) 02/25/2015 13:08:03: Start to install services.
(VM) 02/25/2015 13:08:19: Start to register features.
(VM) 02/25/2015 13:09:38: Start to install application content.
(VM) 02/25/2015 13:09:44: Start to create web application.
WARNING: The specified user FOOBAR15\SP_Farm is a local account. Local accounts should only be used in stand alone
mode.
(VM) 02/25/2015 13:13:57: Start to create default site collection.
(VM) 02/25/2015 13:15:37: Start to pin Visual Studio to Taskbar.
(VM) 02/25/2015 13:15:37: Start to create a link to http://localhost.
(VM) 02/25/2015 13:15:38: Start to update intranet settings
(VM) 02/25/2015 13:15:38: Start to launch localhost
(VM) 02/25/2015 13:20:38: Done. Now you can develop.
0
PS C:\ConfigureDeveloperDesktop\Scripts>
```

Startup time from "cold start" (i.e. flushing IE cache and iisreset):

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D5/3229B66CCCD0E7A203800AA4E5A17334E7B3A4D5.png)

## Creating farm using my script

& '.\\Create Farm.ps1' -CentralAdminAuthProvider NTLM -Verbose\
The local farm is not accessible. Cmdlets with FeatureDependencyId are not registered.\
Passphrase: \*\*\*\*\*\*\*\*\*\
Confirm passphrase: \*\*\*\*\*\*\*\*\*\
Configuration Database Server: **FOOBAR15**\
Configuration Database Name: SharePoint_Config\
Central Administration Database Name: SharePoint_AdminContent\
Central Administration Port: 22812\
Authentication Provider: NTLM

Confirm\
Are you sure you want to perform this action?\
Performing operation "Create Farm.ps1" on Target "**FOOBAR15**".\
[Y] Yes [A] Yes to All [N] No [L] No to All [S] Suspend [?] Help (default is "Y"):\
[2015-02-27 12:54:12] Creating SharePoint farm...\
VERBOSE: [2015-02-27 12:54:12] Start activity - Create SharePoint farm\
VERBOSE: [2015-02-27 12:54:12] Status - Creating the configuration database...\
VERBOSE: [2015-02-27 13:07:10] Status - Installing help collection...\
VERBOSE: [2015-02-27 13:07:10] Status - Initializing security...\
VERBOSE: [2015-02-27 13:07:12] Status - Installing services...\
VERBOSE: [2015-02-27 13:07:36] Status - Registering features...\
VERBOSE: [2015-02-27 13:08:48] Status - Creating the Central Administration site...\
VERBOSE: [2015-02-27 13:10:43] Status - Installing application content...\
VERBOSE: [2015-02-27 13:10:49] Status - Browsing to SharePoint 2013 Central Administration site...\
[2015-02-27 13:10:49] Successfully created SharePoint farm. (Elapsed time: **16:36**)

Compare to **EXT-FOOBAR4** (VirtualBox on WOLVERINE):

& '.\\Create Farm.ps1' -CentralAdminAuthProvider NTLM -Verbose\
The local farm is not accessible. Cmdlets with FeatureDependencyId are not registered.\
Passphrase: \*\*\*\*\*\*\*\*\*\
Confirm passphrase: \*\*\*\*\*\*\*\*\*\
Configuration Database Server: **EXT-FOOBAR4**\
Configuration Database Name: SharePoint_Config\
Central Administration Database Name: SharePoint_AdminContent\
Central Administration Port: 22812\
Authentication Provider: NTLM

Confirm\
Are you sure you want to perform this action?\
Performing the operation "Create Farm.ps1" on target "**EXT-FOOBAR4**".\
[Y] Yes [A] Yes to All [N] No [L] No to All [S] Suspend [?] Help (default is "Y"):\
[2015-02-27 05:24:07] Creating SharePoint farm...\
VERBOSE: [2015-02-27 05:24:07] Start activity - Create SharePoint farm\
VERBOSE: [2015-02-27 05:24:07] Status - Creating the configuration database...\
VERBOSE: [2015-02-27 05:28:23] Status - Installing help collection...\
VERBOSE: [2015-02-27 05:28:23] Status - Initializing security...\
VERBOSE: [2015-02-27 05:28:24] Status - Installing services...\
VERBOSE: [2015-02-27 05:28:28] Status - Registering features...\
VERBOSE: [2015-02-27 05:28:47] Status - Creating the Central Administration site...\
VERBOSE: [2015-02-27 05:29:45] Status - Installing application content...\
VERBOSE: [2015-02-27 05:29:50] Status - Browsing to SharePoint 2013 Central Administration site...\
[2015-02-27 05:29:50] Successfully created SharePoint farm. (Elapsed time: **05:42**)
