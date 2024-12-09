# Migrate TFS to Azure DevOps - v3

Wednesday, February 6, 2019\
12:25 PM

## Planning

### Team Foundation Server to Azure DevOps Services - Migration Guide

### 1 - Get Started

#### Task summary

**Choose datacenter:** Choose the datacenter for your Azure DevOps organization.\
**Download TFS Migrator tool:** Download the TFS Migrator tool from [https://aka.ms/DownloadTFSMigrator](https://aka.ms/DownloadTFSMigrator).\
**Reserve Azure DevOps Services organization(s):** Reserve Azure DevOps Services organization(s) for each of the desired final names.

#### Team project collection mapping worksheet

| Collection name: | **DefaultCollection** | Azure DevOps organization name: | **techtoolbox** |
| ---------------- | --------------------- | ------------------------------- | --------------- |


#### Datacenter location

**Task:** Choose the datacenter for your Azure DevOps Services organization.

| Selected region’s shorthand code: | **CUS** |
| --------------------------------- | ------- |


| **Geographic Region** | **Azure Region**      | **Import Specification Value** |
| --------------------- | --------------------- | ------------------------------ |
| United States         | Central United States | CUS                            |

Azure DevOps Services is available in several Azure [regions](regions). However, not all Azure regions that Azure DevOps Services is present in are supported for import.

**Supported Azure Regions for Import**\
From <[https://docs.microsoft.com/en-us/azure/devops/articles/migration-import?view=azure-devops](https://docs.microsoft.com/en-us/azure/devops/articles/migration-import?view=azure-devops)>

#### Download TFS Migrator tool

**Task:** Download the TFS Migrator tool from [https://aka.ms/DownloadTFSMigrator](https://aka.ms/DownloadTFSMigrator).

Downloaded and extract to **C:\\NotBackedUp\\Temp** on **TT-TFS02**.

#### Reserve your Azure DevOps Services organization name(s)

**Task:** Reserve Azure DevOps Services organization(s) for each of the desired final names.

## 2 - Cloud Prerequisites

### Task summary

**Implement Azure Active Directory:** Make sure your team has a working Azure Active Directory tenant by implementing Azure Active Directory to synchronize with your on-premises Active Directory environment.

### Compliance

#### Our internal data protection and security whitepaper

[https://aka.ms/AzureDevOpsSecurity](https://aka.ms/AzureDevOpsSecurity)

#### Compliance audit report requests

AzureDevOpsImport@microsoft.com - requires NDA with Microsoft

### Azure Active Directory

**Task:** Implement Azure Active Directory to synchronize with your on-premises Active Directory environment.

### Additional security for Cloud authentication

#### Multi-Factor Authentication

[https://aka.ms/AzureADMFA](https://aka.ms/AzureADMFA)

#### Conditional Access

[https://aka.ms/AzureConditionalAccess](https://aka.ms/AzureConditionalAccess)

## 3 - Upgrade TFS

### Task summary

**Upgrade your Team Foundation Server:** Upgrade your Team Foundation Server to one of the supported versions.\
**Run "Configurate Features":** Run the "Configure Features" wizard on every team project in each of your team project collections.

### Timeline of support for TFS versions

[https://aka.ms/AzureDevOpsImportSupportedVersions](https://aka.ms/AzureDevOpsImportSupportedVersions)

### Upgrading Team Foundation Server

**Task:** Upgrade your Team Foundation Server.

#### Upgrade resources

TFS 2018 Upgrade Guide: [https://aka.ms/TFS2018Upgrade](https://aka.ms/TFS2018Upgrade)

**Update a project based on a MSF v4.2 process template**\
From <[https://docs.microsoft.com/en-us/azure/devops/reference/xml/update-a-team-project-v4-dot-2-process-template?view=azure-devops](https://docs.microsoft.com/en-us/azure/devops/reference/xml/update-a-team-project-v4-dot-2-process-template?view=azure-devops)>

**Configuring the "Epics" for upgraded team projects in Team Foundation Server (TFS) 2015**\
From <[https://blogs.msdn.microsoft.com/tfssetup/2015/09/16/configuring-the-epics-for-upgraded-team-projects-in-team-foundation-server-tfs-2015/](https://blogs.msdn.microsoft.com/tfssetup/2015/09/16/configuring-the-epics-for-upgraded-team-projects-in-team-foundation-server-tfs-2015/)>

| **Team Project**         | **Process Template**                      |
| ------------------------ | ----------------------------------------- |
| AdventureWorks           | MSF for Agile Software Development - v4.0 |
| Caelum                   | MSF for Agile Software Development 2013.4 |
| Caliber Construction     | Scrum                                     |
| CommunityServer          | MSF for Agile Software Development - v4.0 |
| CommunitySite            | MSF for Agile Software Development - v4.0 |
| Demo                     | MSF for Agile Software Development v5.0   |
| DinnerNow                | MSF for Agile Software Development v5.0   |
| Dow                      | MSF for Agile Software Development v5.0   |
| Dow Applications         | Microsoft Visual Studio Scrum 2.0         |
| Dow Collaboration        | MSF for Agile Software Development v5.0   |
| Dow FORCE                | MSF for Agile Software Development v5.0   |
| FabrikamSamples          | MSF for Agile Software Development - v4.0 |
| foobar                   | MSF for Agile Software Development v5.0   |
| foobar Agile 2012        | MSF for Agile Software Development 6.0    |
| foobar Agile 2015        | Agile                                     |
| foobar CMMI 2012         | MSF for CMMI Process Improvement 6.0      |
| foobar SCRUM 2012        | Microsoft Visual Studio Scrum 2.0         |
| foobar Scrum 2015        | Scrum                                     |
| foobar2012               | Microsoft Visual Studio Scrum 2.0         |
| foobar2013               | Microsoft Visual Studio Scrum 2013        |
| foobarCMMI               | MSF for CMMI Process Improvement - v4.0   |
| Frontier                 | MSF for Agile Software Development - v4.0 |
| Infrastructure           | Microsoft Visual Studio Scrum 2013.4      |
| KPMG                     | MSF for Agile Software Development - v4.0 |
| Northwind                | MSF for Agile Software Development v5.0   |
| Sagacity                 | MSF for Agile Software Development - v4.0 |
| Securitas ClientPortal   | MSF for Agile Software Development 2013.4 |
| Securitas CloudPortal    | MSF for Agile Software Development v5.0   |
| Securitas EmployeePortal | MSF for Agile Software Development v5.0   |
| SecuritasCustomerPortal  | Scrum                                     |
| Subtext                  | MSF for Agile Software Development v5.0   |
| Toolbox                  | MSF for Agile Software Development - v4.0 |
| Training                 | Microsoft Visual Studio Scrum 2013        |
| Tugboat                  | MSF for Agile Software Development v5.0   |
| WebSites                 | MSF for Agile Software Development - v4.0 |
| Youbiquitous             | MSF for Agile Software Development v5.0   |

```PowerShell
cls
```

#### # Upgrade projects based on old Agile process templates

```PowerShell
$witAdmin = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Enterprise" `
    + "\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer" `
    + "\witadmin.exe"

$tfsCollectionUrl = "https://tfs.technologytoolbox.com/DefaultCollection"
```

##### # Clear TFS cache

```PowerShell
Remove-Item "$env:LOCALAPPDATA\Microsoft\Team Foundation" -Recurse
```

##### # Rename system fields

```PowerShell
@(
    [PSCustomObject] @{Field = "System.AreaId"; NewName = "Area Id";},
    [PSCustomObject] @{Field = "System.AttachedFileCount"; NewName = "Attached File Count";},
    [PSCustomObject] @{Field = "System.ExternalLinkCount"; NewName = "External Link Count";},
    [PSCustomObject] @{Field = "System.HyperLinkCount"; NewName = "Hyperlink Count";},
    [PSCustomObject] @{Field = "System.RelatedLinkCount"; NewName = "Related Link Count";},
    [PSCustomObject] @{Field = "System.IterationId"; NewName = "Iteration ID";}
) |
    foreach {
        & $witAdmin changefield /collection:"$tfsCollectionUrl" `
            /n:"$($_.Field)" /name:"$($_.NewName)"
    }
```

> **Note**
>
> When prompted to change properties for the field, enter **Y** or **yes** to confirm.

```PowerShell
cls
```

##### # (Agile only) Rename Scenario to User Story

```PowerShell
$projects = @(
    "AdventureWorks",
    "CommunityServer",
    "CommunitySite",
    "FabrikamSamples",
    "Frontier",
    "KPMG",
    "Sagacity",
    "Toolbox",
    "Websites")

$projects |
    foreach {
        $projectName = $_

        Write-Host "Processing project ($projectName)..."

        & $witAdmin renamewitd /collection:"$tfsCollectionUrl" `
            /p:"$projectName" /n:Scenario /new:"User Story"
    }
```

> **Note**
>
> When prompted to rename the work item type, enter **Y** or **yes** to confirm.

##### Download the latest version of MSF process template

[https://tfs.technologytoolbox.com/DefaultCollection/\_admin/\_process](https://tfs.technologytoolbox.com/DefaultCollection/_admin/_process)

Export **Agile**

```PowerShell
cls
```

##### # Import link types

```PowerShell
$processExportPath = "C:\NotBackedUp\Temp\Agile"

& $witAdmin importlinktype /collection:"$tfsCollectionUrl" `
    /f:"$processExportPath\WorkItem Tracking\LinkTypes\SharedParameterLink.xml"

& $witAdmin importlinktype /collection:"$tfsCollectionUrl" `
    /f:"$processExportPath\WorkItem Tracking\LinkTypes\SharedStep.xml"

& $witAdmin importlinktype /collection:"$tfsCollectionUrl" `
    /f:"$processExportPath\WorkItem Tracking\LinkTypes\TestedBy.xml"
```

##### (Optional) Apply as needed customizations

##### Backup TFS databases

```PowerShell
cls
```

##### # Clear TFS cache

```PowerShell
Remove-Item "$env:LOCALAPPDATA\Microsoft\Team Foundation" -Recurse
```

##### # Import work item types

```PowerShell
$projects = @(
    "AdventureWorks",
    "Caelum",
    "CommunityServer",
    "CommunitySite",
    "Demo",
    "DinnerNow",
    "Dow",
    "Dow Collaboration",
    "Dow FORCE",
    "FabrikamSamples",
    "foobar",
    "Frontier",
    "KPMG",
    "Northwind",
    "Sagacity",
    "Securitas ClientPortal",
    "Securitas CloudPortal",
    "Securitas EmployeePortal",
    "Subtext",
    "Toolbox",
    "Tugboat",
    "WebSites",
    "Youbiquitous")

$processExportPath = "C:\NotBackedUp\Temp\Agile"

$workItemTypes = @(
    "Bug",
    "CodeReviewRequest",
    "CodeReviewResponse",
    "Epic",
    "Feature",
    "FeedbackRequest",
    "FeedbackResponse",
    "Issue",
    "SharedParameter",
    "SharedStep",
    "Task",
    "TestCase",
    "TestPlan",
    "TestSuite",
    "UserStory")

$projects |
    foreach {
        $projectName = $_

        Write-Host "Processing project ($projectName)..."

        $workItemTypes |
            foreach {
                $workItemType = $_

                Write-Host "Importing work item type ($workItemType)..."

                $filename = ("$processExportPath" `
                    + "\WorkItem Tracking\TypeDefinitions\$workItemType.xml")

                & $witAdmin importwitd /collection:"$tfsCollectionUrl" `
                    /p:"$projectName" /f:"$filename"
        }
    }

...
Importing work item type (CodeReviewResponse)...
Warning: TF248018: You cannot change the "syncnamechanges" attribute of field 'Microsoft.VSTS.Common.ReviewedBy' in a work item type definition. You can only change the value of this attribute by using the witadmin changefield command-line tool. For more information, see the Microsoft Web site:  https://go.microsoft.com/fwlink/?LinkId=759719.
...
```

```PowerShell
cls
```

##### # Import the categories file

```PowerShell
$projects = @(
    "AdventureWorks",
    "Caelum",
    "CommunityServer",
    "CommunitySite",
    "Demo",
    "DinnerNow",
    "Dow",
    "Dow Collaboration",
    "Dow FORCE",
    "FabrikamSamples",
    "foobar",
    "Frontier",
    "KPMG",
    "Northwind",
    "Sagacity",
    "Securitas ClientPortal",
    "Securitas CloudPortal",
    "Securitas EmployeePortal",
    "Subtext",
    "Toolbox",
    "Tugboat",
    "WebSites",
    "Youbiquitous")

$processExportPath = "C:\NotBackedUp\Temp\Agile"
$filename = "$processExportPath\WorkItem Tracking\categories.xml"

$projects |
    foreach {
        $projectName = $_

        Write-Host "Processing project ($projectName)..."

        & $witAdmin importcategories /collection:"$tfsCollectionUrl" `
            /p:"$projectName" /f:"$filename"
    }
```

```PowerShell
cls
```

##### # Import the process configuration file

```PowerShell
$projects = @(
    "AdventureWorks",
    "Caelum",
    "CommunityServer",
    "CommunitySite",
    "Demo",
    "DinnerNow",
    "Dow",
    "Dow Collaboration",
    "Dow FORCE",
    "FabrikamSamples",
    "foobar",
    "Frontier",
    "KPMG",
    "Northwind",
    "Sagacity",
    "Securitas ClientPortal",
    "Securitas CloudPortal",
    "Securitas EmployeePortal",
    "Subtext",
    "Toolbox",
    "Tugboat",
    "WebSites",
    "Youbiquitous")

$processExportPath = "C:\NotBackedUp\Temp\Agile"
$filename = "$processExportPath\WorkItem Tracking\Process\ProcessConfiguration.xml"

$projects |
    foreach {
        $projectName = $_

        Write-Host "Processing project ($projectName)..."

        & $witAdmin importprocessconfig /collection:"$tfsCollectionUrl" `
            /p:"$projectName" /f:"$filename"
    }
```

```PowerShell
cls
```

##### # Delete obsolete work item types

```PowerShell
$obsoleteWorkItemTypes = @(
    "Quality of Service Requirement",
    "Risk")

$projects = @(
    "AdventureWorks",
    "CommunityServer",
    "CommunitySite",
    "FabrikamSamples",
    "Frontier",
    "KPMG",
    "Sagacity",
    "Toolbox",
    "Websites")

$projects |
    foreach {
        $projectName = $_

        Write-Host "Processing project ($projectName)..."

        $obsoleteWorkItemTypes |
            foreach {
                $workItemType = $_

                Write-Host "Deleting obsolete work item type ($workItemType)..."

                & $witAdmin destroywitd /collection:"$tfsCollectionUrl" `
                    /p:"$projectName" /n:"$workItemType"
        }
    }
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

##### Verify access to new features

```PowerShell
cls
```

#### # Upgrade projects based on MSF for CMMI process template

```PowerShell
$witAdmin = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Enterprise" `
    + "\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer" `
    + "\witadmin.exe"

$tfsCollectionUrl = "https://tfs.technologytoolbox.com/DefaultCollection"
```

##### Download the latest version of MSF process template

[https://tfs.technologytoolbox.com/DefaultCollection/\_admin/\_process](https://tfs.technologytoolbox.com/DefaultCollection/_admin/_process)

Export **MSF for CMMI Process Improvement 2013.4**

```PowerShell
cls
```

##### # Import link types

```PowerShell
$processExportPath = "C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4"

& $witAdmin importlinktype /collection:"$tfsCollectionUrl" `
    /f:"$processExportPath\WorkItem Tracking\LinkTypes\Affects.xml"
```

##### (Optional) Apply as needed customizations

##### Backup TFS databases

```PowerShell
cls
```

##### # Clear TFS cache

```PowerShell
Remove-Item "$env:LOCALAPPDATA\Microsoft\Team Foundation" -Recurse
```

##### # Import work item types

```PowerShell
$projects = @("foobarCMMI")

$processExportPath = "C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4"

$workItemTypes = @(
    "Bug",
    "ChangeRequest",
    "CodeReviewRequest",
    "CodeReviewResponse",
    "Feature",
    "FeedbackRequest",
    "FeedbackResponse",
    "Issue",
    "Requirement",
    "Review",
    "Risk",
    "SharedParameter",
    "SharedStep",
    "Task",
    "TestCase",
    "TestPlan",
    "TestSuite")

$projects |
    foreach {
        $projectName = $_

        Write-Host "Processing project ($projectName)..."

        $workItemTypes |
            foreach {
                $workItemType = $_

                Write-Host "Importing work item type ($workItemType)..."

                $filename = ("$processExportPath" `
                    + "\WorkItem Tracking\TypeDefinitions\$workItemType.xml")

                & $witAdmin importwitd /collection:"$tfsCollectionUrl" `
                    /p:"$projectName" /f:"$filename"
        }
    }
```

```PowerShell
cls
```

##### # Import the categories file

```PowerShell
$projects = @("foobarCMMI")

$processExportPath = "C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4"

$filename = "$processExportPath\WorkItem Tracking\categories.xml"

$projects |
    foreach {
        $projectName = $_

        Write-Host "Processing project ($projectName)..."

        & $witAdmin importcategories /collection:"$tfsCollectionUrl" `
            /p:"$projectName" /f:"$filename"
    }
```

```PowerShell
cls
```

##### # Import the process configuration file

```PowerShell
$projects = @("foobarCMMI")

$filename = "$processExportPath\WorkItem Tracking\Process\ProcessConfiguration.xml"

$projects |
    foreach {
        $projectName = $_

        Write-Host "Processing project ($projectName)..."

        & $witAdmin importprocessconfig /collection:"$tfsCollectionUrl" `
            /p:"$projectName" /f:"$filename"
    }
```

##### Verify access to new features

#### Post-upgrade steps

#### Configure Features wizard

**Task:** Run the "Configure Features" wizard on every team project in each of your team project collections.

[https://aka.ms/TFSConfigureFeatures](https://aka.ms/TFSConfigureFeatures)

## 4 - Validate Your TFS Server

### Task summary

**Run validations with TFS Migration tool:** Run the validation of each team project collection database with the TFS Migrator tool.\
**Review logs and fix errors:** Review the logs and fix any errors that were found.\
**Repeat validation checks:** Repeat the validation and error fixing process until there are no more errors remaining in the logs.

### Validating a team project collection

**Task:** Run the validation of each team project collection database with the TFS Migrator tool.

```PowerShell
cd C:\NotBackedUp\Temp\TfsMigrator

$tfsCollectionUrl = "https://tfs.technologytoolbox.com/DefaultCollection"

.\TfsMigrator.exe Validate /collection:"$tfsCollectionUrl" /SaveProcesses
```

### Review validation warnings and errors

**Task:** Review the logs and fix any errors that were found.

#### Validation errors - "ISVError:100014 An expected permission is missing..."

```Text
[Error  @14:27:22.374] ISVError:100014 An expected permission is missing. Missing Permission:Read for Group:S-1-9-1551374245-3344735283-2770398789-2205379467-3927774480-0-0-0-0-3 and Scope:69e50941-bc62-4ae5-a381-137d39fb622c, please refer to the documentation to fix this permission and retry.
[Error  @14:27:22.420] ISVError:100014 An expected permission is missing. Missing Permission:Read for Group:S-1-9-1551374245-1155208912-3483930690-2635630741-1161063796-0-0-0-0-3 and Scope:823731da-ae68-4446-bc70-f6c3b5ebc534, please refer to the documentation to fix this permission and retry.
[Error  @14:27:23.061] ISVError:100014 An expected permission is missing. Missing Permission:Read for Group:S-1-9-1551374245-710121227-400029000-2718948435-2366881837-0-0-0-0-3 and Scope:5a2d48a4-bc0b-471e-89b2-76510bd90069, please refer to the documentation to fix this permission and retry.
[Error  @14:27:23.139] ISVError:100014 An expected permission is missing. Missing Permission:Read for Group:S-1-9-1551374245-2766517610-4234627661-2908094125-2749101271-0-0-0-0-3 and Scope:44b80241-9148-415f-9bd2-391e633b37b5, please refer to the documentation to fix this permission and retry.
...
```

##### Solution

```Console
TFSSecurity.exe /a+ Identity "69e50941-bc62-4ae5-a381-137d39fb622c\\" ^
    Read sid:S-1-9-1551374245-3344735283-2770398789-2205379467-3927774480-0-0-0-0-3 ALLOW ^
    /collection:https://tfs.technologytoolbox.com/DefaultCollection

TFSSecurity.exe /a+ Identity "823731da-ae68-4446-bc70-f6c3b5ebc534\\" ^
    Read sid:S-1-9-1551374245-1155208912-3483930690-2635630741-1161063796-0-0-0-0-3 ALLOW ^
    /collection:https://tfs.technologytoolbox.com/DefaultCollection

TFSSecurity.exe /a+ Identity "5a2d48a4-bc0b-471e-89b2-76510bd90069\\" ^
    Read sid:S-1-9-1551374245-710121227-400029000-2718948435-2366881837-0-0-0-0-3 ALLOW ^
    /collection:https://tfs.technologytoolbox.com/DefaultCollection

TFSSecurity.exe /a+ Identity "44b80241-9148-415f-9bd2-391e633b37b5\\" ^
    Read sid:S-1-9-1551374245-2766517610-4234627661-2908094125-2749101271-0-0-0-0-3 ALLOW ^
    /collection:https://tfs.technologytoolbox.com/DefaultCollection
```

##### Reference

... If the group that was flagged ends with "0-0-0-0-3", such as in the example below, then you will need to fix a missing permission for the "Project Collection Valid Users" group. Run the below command against TFSSecurity.exe after replacing the scope with the one from the error message and adding in your collection URL.

```Console
    TFSSecurity.exe /a+ Identity "{scope}\\" Read sid:{Group SID} ALLOW /collection:{collectionUrl}
```

From <[https://docs.microsoft.com/en-us/azure/devops/articles/migration-troubleshooting?view=azure-devops](https://docs.microsoft.com/en-us/azure/devops/articles/migration-troubleshooting?view=azure-devops)>

#### Process template errors

#### Collection size

#### SQL Database collation

### Repeating the validation checks

**Task:** Repeat this validation and error fixing process until there are no more errors remaining in the logs.

## 5 - Get Ready for Import

### Task summary

**Assign, activate, and map Azure DevOps Services subscriptions:** Ensure that each of the Visual Studio (formerly MSDN) subscriptions are assigned, activated, and mapped to each subscriber’s Azure Active Directory organization.\
**Generate import settings:** Generate import settings and related files using the TfsMigrator prepare command.\
**Provide the configurable settings:** Provide the configurable settings in the Import Specification file.\
**Review** the Identity Map log file\
**Task:** Create an Azure Storage Container in the same datacenter as the final Azure DevOps Services organization.

### Subscriptions

**Task:** Ensure that each of the Visual Studio (formerly MSDN) subscriptions are assigned, activated, and mapped to each subscriber’s Azure Active Directory organization.

#### Assign subscription

#### Activate subscription

#### Link subscription to Azure Active Directory organization

#### Help with subscriptions

### Generate import files with prepare step in TfsMigrator

Add the following sites to the Trusted Sites zone in Internet Explorer:

- [https://aadcdn.msftauth.net](https://aadcdn.msftauth.net)
- [https://login.microsoftonline.com](https://login.microsoftonline.com)
- [https://secure.aadcdn.microsoftonline-p.com](https://secure.aadcdn.microsoftonline-p.com)

```Console
.\TfsMigrator.exe Prepare /collection:https://tfs.technologytoolbox.com/DefaultCollection /tenantDomainName:technologytoolbox.com /region:CUS
```

**Task:** Generate import settings and related files using the TfsMigrator prepare command.

#### Import specification file

**Task:** Provide the configurable settings in the Import Specification file.

#### Identity Map Log

**Task:** Review the Identity Map log file

##### Historical vs. active identities

Historical identities:

- TT-TFS02\\foo
- TECHTOOLBOX\\SUPPORT_388945a0
- TECHTOOLBOX\\superman
- TECHTOOLBOX\\MSOL_c1a5a232cfc3
- TECHTOOLBOX\\krbtgt
- TECHTOOLBOX\\EXTRANET\$
- TECHTOOLBOX\\DefaultAccount
- CYCLOPS\\foo

##### Licenses

##### Azure DevOps Subscriptions

**Task:** Verify and update licenses in the identity map

This step is no longer applicable (i.e. licensing information is no longer included in IdentityMap.csv).

### Create an Azure Storage Container in chosen datacenter

**Task:** Create an Azure Storage Container in the same datacenter as the final Azure DevOps Services organization.

| Azure Storage Container Name: | **techtoolboxtfsmigration**         |
| ----------------------------- | ----------------------------------- |
| Datacenter Location:          | **Central US**                      |
| Replication:                  | **Locally-redundant storage (LRS)** |

### Set up Azure subscription for billing

## 6 - Import

### Task summary

**Dry run of end-to-end import:** Complete a dry run of the end-to-end import before scheduling your production import.\
**Detach the team project collection:** Detach the team project collection in TFS Administration Console.\
**Create portable backup:** Create portable backup of the Team Project Collection SQL database.\
**Upload SQL database backup:** Upload SQL database backup and identity map to Azure Storage Container.\
**Generate SAS key:** Generate a SAS key for the Azure Storage container and modify your import settings file to include the SAS Key.\
**Delete previous dry run organizations:** Delete any previous dry run Azure DevOps Services organizations.\
**Rename imported organization:** Rename the imported Azure DevOps Services organization to the desired name that was reserved in Phase 1.\
**Set up billing:** Set up the billing for the Azure DevOps Services Organization with the Azure subscription identified in Phase 5.\
**Reconnect to new organization:** Reconnect on-premises build servers to the newly-imported Azure DevOps Services organization.

**Task:** Complete a dry run of the end to end import before scheduling your production import.

### Considerations for roll back planning

### Timing worksheet

#### Time for each step

|                                                                       | Dry Run Import #1 | Dry Run Import #2 | Dry Run Import #3 |
| --------------------------------------------------------------------- | ----------------- | ----------------- | ----------------- |
| Detach Collection                                                     | ~5 minutes        |                   |                   |
| Generate Backup of SQL Database                                       | ~5 minutes        |                   |                   |
| Upload Backup and Identity Map to Azure Storage                       | ~30 minutes       |                   |                   |
| Queue Import                                                          |                   |                   |                   |
| Final UAT Verification of Imported Azure DevOps Services Organization |                   |                   |                   |

### Detach your team project collection from Team Foundation Server

**Task:** Detach the team project collection in TFS Administration Console.

---

**TT-SQL02** - Run as administrator

```PowerShell
cls
```

### # Generate database backup

```PowerShell
Push-Location "C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin"

& .\SqlPackage.exe `
    /sourceconnectionstring:"Data Source=localhost;Initial Catalog=Tfs_DefaultCollection;Integrated Security=True" `
    /targetFile:"Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Tfs_DefaultCollection.dacpac" `
    /action:extract `
    /p:ExtractAllTableData=true `
    /p:IgnoreUserLoginMappings=true `
    /p:IgnorePermissions=true `
    /p:Storage=Memory

Pop-Location
```

---

**Task:** Create portable backup of the team project collection SQL database.

### Dry run only: attach team project collection again

### Upload backup to Azure Storage Container

#### Create blob container in Azure Storage

| Name: | **import** |
| ----- | ---------- |


#### Install AzCopy

**Download and install AzCopy on Windows**\
From <[https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy)>

---

**TT-SQL02** - Run as administrator

```PowerShell
cls
```

#### # Copy backup to Azure storage container

```PowerShell
$key = {key}
$filename = "Tfs_DefaultCollection.dacpac"
$source = "Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\$filename"
$destination = "https://techtoolboxtfsmigration.blob.core.windows.net/import/$filename"

& 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' `
    /Source:$source `
    /Dest:$destination `
    /DestKey:$key

Finished 1 of total 1 file(s).
[2019/02/08 09:35:37] Transfer summary:
-----------------
Total files transferred: 1
Transfer successfully:   1
Transfer skipped:        0
Transfer failed:         0
Elapsed time:            00.00:29:34
```

---

**Task:** Upload SQL database backup and identity map to Azure Storage Container

#### Generate SAS key for the Azure Storage Container

##### Install Azure Storage Explorer

**Azure Storage Explorer**\
From <[https://storageexplorer.com/](https://storageexplorer.com/)>

**Task:** Generate a SAS key for the Azure Storage container and modify your import settings file to include the SAS key.

### Delete previous dry run import Azure DevOps Services organizations

**Task:** Delete any previous dry run Azure DevOps Services organizations.

### Queue the import

---

**STORM** - Run as administrator

```PowerShell
cls
```

#### # Queue import

```PowerShell
Push-Location C:\NotBackedUp\Temp\TfsMigrator

.\TfsMigrator.exe import /importFile:"C:\NotBackedUp\Temp\import.json"

Microsoft Team Foundation Server (R) Tfs Migrator Tool version 16.132.28529.3
Copyright (C) Microsoft Corporation. All rights reserved.

-------------------------------------
  Validating Import File
-------------------------------------

Validating import specification file...

Validation completed successfully.

Validating import source and target regions...
Validation completed successfully.

-------------------------------------
  Importing Collection
-------------------------------------

[IMPORTANT] You are about to initiate an import of your collection into Azure DevOps Services.
A new Azure DevOps Services organization will be created that you will own.
Your data could be held in a secured location in the region that you're importing into for up to 7 days, as a staging point for the import process.
After that period has ended, your staged data will be deleted.

Please confirm that you wish to continue with moving your data to Azure DevOps Services.

Are you sure you want to continue? (Yes/No) y

Starting the Import ...

Import has been successfully started!

Monitor import: https://dev.azure.com/techtoolbox-test1-dryrun
Import ID: 5b3b3720-6da5-4eef-8659-1ca37c73617d

Execution Time: 0:00:24.3342235
Output Folder:  C:\NotBackedUp\Temp\TfsMigrator\Logs\Imports\20190208_101303


Pop-Location
```

---

### Post-import steps

#### Rename final imported organization to desired name

**Task:** Rename the imported Azure DevOps Services organization to the desired name that was reserved in Phase 1.

#### Set up billing

**Task:** Setup the billing for the Azure DevOps Services Organization with the Azure subscription identified in Phase 5.

#### Configure build agents

**Task:** Reconnect on-premises build servers to the newly imported Azure DevOps Services organization.

#### Hosted build and deployment pipelines

## References

**Migrate data from TFS to Azure DevOps Services**\
From <[https://docs.microsoft.com/en-us/azure/devops/articles/migration-overview?view=azure-devops](https://docs.microsoft.com/en-us/azure/devops/articles/migration-overview?view=azure-devops)>

GitHub - Microsoft/process-customization-scripts

### Restart TFS

```PowerShell
cls
& 'C:\Program Files\Microsoft Team Foundation Server 2018\Tools\TfsServiceControl.exe' quiesce
```

```PowerShell
cls
& 'C:\Program Files\Microsoft Team Foundation Server 2018\Tools\TfsServiceControl.exe' unquiesce
```
