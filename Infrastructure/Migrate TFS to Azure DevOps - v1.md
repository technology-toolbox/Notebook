# Migrate TFS to Azure DevOps - v1

Wednesday, February 6, 2019
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

**Task:** Download the TFS Migrator tool from  [https://aka.ms/DownloadTFSMigrator](https://aka.ms/DownloadTFSMigrator).

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

**Task:** Implement Azure Active Directory to synchronize with your  on-premises Active Directory environment.

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

#### Upgrade projects based on MSF v4.0 process template

```Console
cd "%programfiles(x86)%\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
```

```Console
cls
```

##### REM Clear TFS cache

```Console
rmdir "C:\Users\jjameson-admin\AppData\Local\Microsoft\Team Foundation" /s /q
```

```Console
cls
```

##### REM Rename system fields

```Console
witadmin changefield /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /n:System.AreaId /name:"Area Id"
```

> **Note**
>
> When prompted to change properties for the field, enter **Y** or **yes** to confirm.

```Console
witadmin changefield /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /n:System.AttachedFileCount /name:"Attached File Count"
```

> **Note**
>
> When prompted to change properties for the field, enter **Y** or **yes** to confirm.

```Console
witadmin changefield /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /n:System.ExternalLinkCount /name:"External Link Count"
```

> **Note**
>
> When prompted to change properties for the field, enter **Y** or **yes** to confirm.

```Console
witadmin changefield /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /n:System.HyperLinkCount /name:"Hyperlink Count"
```

> **Note**
>
> When prompted to change properties for the field, enter **Y** or **yes** to confirm.

```Console
witadmin changefield /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /n:System.RelatedLinkCount /name:"Related Link Count"
```

> **Note**
>
> When prompted to change properties for the field, enter **Y** or **yes** to confirm.

```Console
cls
```

##### REM (Agile only) Rename Scenario to User Story

```Console
witadmin renamewitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks /n:Scenario /new:"User Story"
```

> **Note**
>
> When prompted to rename the work item type, enter **Y** or **yes** to confirm.

```Console
witadmin renamewitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer /n:Scenario /new:"User Story"
```

> **Note**
>
> When prompted to rename the work item type, enter **Y** or **yes** to confirm.

```Console
witadmin renamewitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite /n:Scenario /new:"User Story"
```

> **Note**
>
> When prompted to rename the work item type, enter **Y** or **yes** to confirm.

```Console
witadmin renamewitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples /n:Scenario /new:"User Story"
```

> **Note**
>
> When prompted to rename the work item type, enter **Y** or **yes** to confirm.

```Console
witadmin renamewitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier /n:Scenario /new:"User Story"
```

> **Note**
>
> When prompted to rename the work item type, enter **Y** or **yes** to confirm.

```Console
witadmin renamewitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG /n:Scenario /new:"User Story"
```

> **Note**
>
> When prompted to rename the work item type, enter **Y** or **yes** to confirm.

```Console
witadmin renamewitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity /n:Scenario /new:"User Story"
```

> **Note**
>
> When prompted to rename the work item type, enter **Y** or **yes** to confirm.

```Console
witadmin renamewitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox /n:Scenario /new:"User Story"
```

> **Note**
>
> When prompted to rename the work item type, enter **Y** or **yes** to confirm.

```Console
witadmin renamewitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Websites /n:Scenario /new:"User Story"
```

> **Note**
>
> When prompted to rename the work item type, enter **Y** or **yes** to confirm.

##### Download the latest version of MSF process template

[https://tfs.technologytoolbox.com/DefaultCollection/_admin/_process](https://tfs.technologytoolbox.com/DefaultCollection/_admin/_process)

Export **MSF for Agile Software Development 2013.4**

```Console
cls
```

##### REM Import link types

```Console
witadmin importlinktype /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\LinkTypes\TestedBy.xml"

witadmin importlinktype /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\LinkTypes\SharedStep.xml"

witadmin importlinktype /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\LinkTypes\SharedParameterLink.xml"
```

##### (Optional) Apply as needed customizations

##### Backup TFS databases

```Console
cls
```

##### REM Clear TFS cache

```Console
rmdir "C:\Users\jjameson-admin\AppData\Local\Microsoft\Team Foundation" /s /q
```

```Console
cls
```

##### REM Import work item types

###### REM Import work item types for AdventureWorks project

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Bug.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Feature.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Issue.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedParameter.xml"

TF26177: The field System.IterationId cannot be renamed from 'IterationID' to 'Iteration ID'.
```

> **Note**
>
> Edit **SharedParameter.xml** to remove space in field name, i.e. change:
>
> ```XML
>       <FIELD name="Iteration ID" refname="System.IterationId" type="Integer" />
> ```
>
> to:
>
> ```XML
>       <FIELD name="IterationID" refname="System.IterationId" type="Integer" />
> ```
>
> Reference:
>
> **Problem with update a process template Scrum 2014.3 to scrum 2015 (update 2).**\
> From <[https://social.msdn.microsoft.com/Forums/vstudio/en-US/c6918c76-63da-4050-8fe8-b9fd335a5aab/problem-with-update-a-process-template-scrum-20143-to-scrum-2015-update-2?forum=tfsprocess](https://social.msdn.microsoft.com/Forums/vstudio/en-US/c6918c76-63da-4050-8fe8-b9fd335a5aab/problem-with-update-a-process-template-scrum-20143-to-scrum-2015-update-2?forum=tfsprocess)>

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedStep.xml"

TF26177: The field System.IterationId cannot be renamed from 'IterationID' to 'Iteration ID'.
```

> **Note**
>
> Edit **SharedStep.xml** to remove space in field name, i.e. change:
>
> ```XML
>       <FIELD name="Iteration ID" refname="System.IterationId" type="Integer" />
> ```
>
> to:
>
> ```XML
>       <FIELD name="IterationID" refname="System.IterationId" type="Integer" />
> ```
>
> Reference:
>
> **Problem with update a process template Scrum 2014.3 to scrum 2015 (update 2).**\
> From <[https://social.msdn.microsoft.com/Forums/vstudio/en-US/c6918c76-63da-4050-8fe8-b9fd335a5aab/problem-with-update-a-process-template-scrum-20143-to-scrum-2015-update-2?forum=tfsprocess](https://social.msdn.microsoft.com/Forums/vstudio/en-US/c6918c76-63da-4050-8fe8-b9fd335a5aab/problem-with-update-a-process-template-scrum-20143-to-scrum-2015-update-2?forum=tfsprocess)>

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Task.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\TestCase.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\UserStory.xml"
```

```Console
cls
```

###### REM Import work item types for CommunityServer project

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Bug.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Feature.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Issue.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedParameter.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedStep.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Task.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\TestCase.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\UserStory.xml"
```

```Console
cls
```

###### REM Import work item types for CommunitySite project

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Bug.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Feature.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Issue.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedParameter.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedStep.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Task.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\TestCase.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\UserStory.xml"
```

```Console
cls
```

###### REM Import work item types for FabrikamSamples project

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Bug.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Feature.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Issue.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedParameter.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedStep.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Task.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\TestCase.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\UserStory.xml"
```

```Console
cls
```

###### REM Import work item types for Frontier project

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Bug.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Feature.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Issue.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedParameter.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedStep.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Task.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\TestCase.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\UserStory.xml"
```

```Console
cls
```

###### REM Import work item types for KPMG project

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Bug.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Feature.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Issue.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedParameter.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedStep.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Task.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\TestCase.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\UserStory.xml"
```

```Console
cls
```

###### REM Import work item types for Sagacity project

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Bug.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Feature.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Issue.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedParameter.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedStep.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Task.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\TestCase.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\UserStory.xml"
```

```Console
cls
```

###### REM Import work item types for Toolbox project

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Bug.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Feature.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Issue.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedParameter.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedStep.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Task.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\TestCase.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\UserStory.xml"
```

```Console
cls
```

###### REM Import work item types for WebSites project

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Bug.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Feature.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Issue.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedParameter.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\SharedStep.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\Task.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\TestCase.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\TypeDefinitions\UserStory.xml"
```

```Console
cls
```

##### REM Import the categories file

###### REM Import categories file for AdventureWorks project

```Console
witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\categories.xml"
```

###### REM Import categories file for CommunityServer project

```Console
witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\categories.xml"
```

###### REM Import categories file for CommunitySite project

```Console
witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\categories.xml"
```

###### REM Import categories file for FabrikamSamples project

```Console
witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\categories.xml"
```

###### REM Import categories file for Frontier project

```Console
witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\categories.xml"
```

###### REM Import categories file for KPMG project

```Console
witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\categories.xml"
```

###### REM Import categories file for Sagacity project

```Console
witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\categories.xml"
```

###### REM Import categories file for Toolbox project

```Console
witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\categories.xml"
```

###### REM Import categories file for WebSites project

```Console
witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\categories.xml"
```

cls

##### REM Import the process configuration file

###### REM Import the process configuration file for AdventureWorks project

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

###### REM Import the process configuration file for CommunityServer project

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

###### REM Import the process configuration file for CommunitySite project

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

###### REM Import the process configuration file for FabrikamSamples project

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

###### REM Import the process configuration file for Frontier project

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

###### REM Import the process configuration file for KPMG project

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

###### REM Import the process configuration file for Sagacity project

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

###### REM Import the process configuration file for Toolbox project

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

###### REM Import the process configuration file for WebSites project

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\MSF for Agile Software Development 2013.4\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

```Console
cls
```

###### REM Delete obsolete work item type - Quality of Service Requirement

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks /n:"Quality of Service Requirement"
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer /n:"Quality of Service Requirement"
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite/n:"Quality of Service Requirement"
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples /n:"Quality of Service Requirement"
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier /n:"Quality of Service Requirement"
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG /n:"Quality of Service Requirement"
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity /n:"Quality of Service Requirement"
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox /n:"Quality of Service Requirement"
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites /n:"Quality of Service Requirement"
```

```Console
cls
```

###### REM Delete obsolete work item type - Risk

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks /n:Risk
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer /n:Risk
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite /n:Risk
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples /n:Risk
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier /n:Risk
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG /n:Risk
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity /n:Risk
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox /n:Risk
```

> **Note**
>
> When prompted to destroy the work item type, confirm there are 0 work items based on the type and then enter **Y** or **yes** to confirm.

```Console
witadmin destroywitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites /n:Risk
```

##### Verify access to new features

#### Upgrade projects based on MSF for CMMI process template

```Console
cd "%programfiles(x86)%\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
```

##### Download the latest version of CMMI process template

[https://tfs.technologytoolbox.com/DefaultCollection/_admin/_process](https://tfs.technologytoolbox.com/DefaultCollection/_admin/_process)

Export **MSF for CMMI Process Improvement 2013.4**

```Console
cls
```

##### REM Import link types

```Console
witadmin importlinktype /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\LinkTypes\Affects.xml"
```

##### (Optional) Apply as needed customizations

##### Backup TFS databases

```Console
cls
```

##### REM Clear TFS cache

```Console
rmdir "C:\Users\jjameson-admin\AppData\Local\Microsoft\Team Foundation" /s /q
```

```Console
cls
```

##### REM Import work item types

###### REM Import work item types for foobarCMMI project

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\Bug.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\ChangeRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\CodeReviewResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\Feature.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackRequest.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\FeedbackResponse.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\Issue.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\Requirement.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\Review.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\Risk.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\SharedParameter.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\SharedStep.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\Task.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\TestCase.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\TestPlan.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\TypeDefinitions\TestSuite.xml"
```

```Console
cls
```

##### REM Import the categories file

###### REM Import categories file for foobarCMMI project

```Console
witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\categories.xml"
```

```Console
cls
```

##### REM Import the process configuration file

###### REM Import the process configuration file for foobarCMMI project

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobarCMMI ^
    /f:"C:\NotBackedUp\Temp\MSF for CMMI Process Improvement 2013.4\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

##### Verify access to new features

#### Add Epic work item type to projects based on MSF for Agile 4.0/5.0 process templates

```Console
cd "%programfiles(x86)%\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"
```

##### Download the latest version of Agile process template

[https://tfs.technologytoolbox.com/DefaultCollection/_admin/_process](https://tfs.technologytoolbox.com/DefaultCollection/_admin/_process)

Export **Agile**

##### Backup TFS databases

```Console
cls
```

##### REM Clear TFS cache

```Console
rmdir "C:\Users\jjameson-admin\AppData\Local\Microsoft\Team Foundation" /s /q
```

```Console
cls
```

##### REM Import Epic work item type

```Console
witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Demo ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:DinnerNow ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Dow ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Dow Collaboration" ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Dow FORCE" ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobar ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Northwind ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Securitas CloudPortal" ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Securitas EmployeePortal" ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Subtext^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Tugboat ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"

witadmin importwitd /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Youbiquitous ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\TypeDefinitions\Epic.xml"
```

```Console
cls
```

##### REM Import the categories file

```Console
witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Demo ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:DinnerNow ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Dow ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Dow Collaboration" ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Dow FORCE" ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobar ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Northwind ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Securitas CloudPortal" ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Securitas EmployeePortal" ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Subtext ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Tugboat ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"

witadmin importcategories /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Youbiquitous ^
    /f:"C:\NotBackedUp\Temp\Agile\WorkItem Tracking\categories.xml"
```

```Console
cls
```

##### REM Update process configuration file

###### REM Export process template for project based on "MSF for Agile Software Development - v4.0" process template

```Console
witadmin exportprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\AdventureWorks\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

###### REM Export process template for project based on "MSF for Agile Software Development v5.0" process template

```Console
witadmin exportprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobar ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

###### Update process configuration files to add Epic portfolio backlog

Use DiffMerge to compare/merge changes from Agile process configuration file

```Console
cls
```

###### REM Import process configuration file for projects based on "MSF for Agile Software Development - v4.0" process template

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:AdventureWorks ^
    /f:"C:\NotBackedUp\Temp\AdventureWorks\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunityServer ^
    /f:"C:\NotBackedUp\Temp\AdventureWorks\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:CommunitySite ^
    /f:"C:\NotBackedUp\Temp\AdventureWorks\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:FabrikamSamples ^
    /f:"C:\NotBackedUp\Temp\AdventureWorks\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Frontier ^
    /f:"C:\NotBackedUp\Temp\AdventureWorks\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:KPMG ^
    /f:"C:\NotBackedUp\Temp\AdventureWorks\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Sagacity ^
    /f:"C:\NotBackedUp\Temp\AdventureWorks\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Toolbox ^
    /f:"C:\NotBackedUp\Temp\AdventureWorks\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:WebSites ^
    /f:"C:\NotBackedUp\Temp\AdventureWorks\WorkItem Tracking\Process\ProcessConfiguration.xml"
```

###### REM Import process configuration file for projects based on "MSF for Agile Software Development v5.0" process template

```Console
witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Demo ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:DinnerNow ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Dow ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Dow Collaboration" ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Dow FORCE" ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:foobar ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Northwind ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Securitas CloudPortal" ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:"Securitas EmployeePortal" ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Subtext ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Tugboat ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"

witadmin importprocessconfig /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /p:Youbiquitous ^
    /f:"C:\NotBackedUp\Temp\foobar\WorkItem Tracking\Process\ProcessConfiguration.xml"
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

```Console
cd C:\NotBackedUp\Temp\TfsMigrator

TfsMigrator Validate /collection:https://tfs.technologytoolbox.com/DefaultCollection /SaveProcesses
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

#### Validation errors - "TF402556: For field System.IterationId to be well defined, you must name it Iteration ID..."

```Text
[Info   @14:04:53.773] Step : ProcessValidation - Failure Type - INFO : Starting validation of project 1=AdventureWorks, process=c:\temp\PT20190207210235493\AdventureWorks.zip
[Info   @14:04:53.820] Step : ProcessValidation - Failure Type - INFO : AllowCustomTeamField: False.
[Error  @14:05:02.101] Step : ProcessValidation - Failure Type - Validation failed : Invalid process template: WorkItem Tracking\TypeDefinitions\Bug.xml:8: TF402556: For field System.IterationId to be well defined, you must name it Iteration ID and set its type to Integer. Provided Field Name is IterationID and type is Integer
[Error  @14:05:02.101] Step : ProcessValidation - Failure Type - Validation failed : Invalid process template: WorkItem Tracking\TypeDefinitions\Task.xml:8: TF402556: For field System.IterationId to be well defined, you must name it Iteration ID and set its type to Integer. Provided Field Name is IterationID and type is Integer
[Error  @14:05:02.101] Step : ProcessValidation - Failure Type - Validation failed : Invalid process template: WorkItem Tracking\TypeDefinitions\QualityofServiceRequirement.xml:8: TF402556: For field System.IterationId to be well defined, you must name it Iteration ID and set its type to Integer. Provided Field Name is IterationID and type is Integer
[Error  @14:05:02.101] Step : ProcessValidation - Failure Type - Validation failed : Invalid process template: WorkItem Tracking\TypeDefinitions\UserStory.xml:8: TF402556: For field System.IterationId to be well defined, you must name it Iteration ID and set its type to Integer. Provided Field Name is IterationID and type is Integer
...
```

##### Solution

```Console
witadmin changefield /collection:https://tfs.technologytoolbox.com/DefaultCollection ^
    /n:System.IterationId /name:"Iteration ID"
```

##### Reference

**TF402556: For field System.IterationId to be well defined, you must name it Iteration ID and set its type to Integer.**\
This error is typical for old process templates that have not been updated in some time. Try running the [configure features wizard](configure features wizard) on each project. Alternatively you can run the follow witadmin command:

```Console
    witadmin changefield /collection:http://AdventureWorksServer:8080/tfs/DefaultCollection /n:fieldname /name:newname
```

From <[https://docs.microsoft.com/en-us/azure/devops/articles/migration-processtemplates?view=azure-devops](https://docs.microsoft.com/en-us/azure/devops/articles/migration-processtemplates?view=azure-devops)>

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

- [https://login.microsoftonline.com](https://login.microsoftonline.com)
- [https://secure.aadcdn.microsoftonline-p.com](https://secure.aadcdn.microsoftonline-p.com)

```Console
TfsMigrator Prepare /collection:https://tfs.technologytoolbox.com/DefaultCollection /tenantDomainName:contoso.com /region:CUS
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

**TT-SQL02**

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

**TT-SQL02**

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

**TT-SQL02**

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
