# TFS Builds

Wednesday, April 4, 2018\
11:13 AM

## Configure build definition for team project

### Baseline build using ".NET Desktop" template

### Specify branch in workspace mapping

| **Task: Get sources** |                                  |
| --------------------- | -------------------------------- |
|                       |                                  |
| Server path           | \$/Securitas EmployeePortal/Main |

Section: Workspace mappings

### Remove cloaked folder in workspace mapping

> **Comment**
>
> Remove cloaked folder in workspace mapping to fix error in Team build:
>
> \$/Securitas EmployeePortal/Drops' cannot be cloaked because it does not have a mapped parent.

### Specify solution file to build

> **Comment**
>
> Specify solution file to build (since using "\*\*\\\*.sln" can be problematic with node_modules folder)

Process\
Section: Parameters\
Solution: \$/Securitas EmployeePortal/Main/Code/Securitas.EmployeePortal.sln

### Skip integration tests

Task: VsTest - testAssemblies\
Section: Test selection\
Test filter criteria: TestCategory!=Integration

### Configure build task

> **Comment**
>
> Configure MSBuild Arguments to create deployment package for web project
>
> Enable "Clean" option in build task

Task: Build solution...\
MSBuild Arguments: /p:DeployOnBuild=True /p:IsPackaging=True\
Clean: true

### Set MSBuild arguments to match build definition for ASP.NET projects

| **Task: Build solution...** |  |
| --- | --- |
|  |  |
| MSBuild Arguments | /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true /p:PackageLocation="\$(Build.ArtifactStagingDirectory)\\\\" |

### Modify "Get sources" task to clean all build directories

| **Task: Get sources** |                       |
| --------------------- | --------------------- |
| Clean                 | true                  |
| Clean options         | All build directories |

### Update drop location

> **Comment**
>
> Change drop location to file share and add "\$(BuildConfiguration)" to package path

| **Task: Build solution...** |  |
| --- | --- |
| MSBuild Arguments | /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true /p:PackageLocation="\$(Build.ArtifactStagingDirectory)\\\\\$(BuildConfiguration)\\\\" |

| **Task: Publish Artifact...** |  |
| --- | --- |
| Artifact Type | File share |
| Path | [\\\\TT-FS01\\Builds\\Securitas\\EmployeePortal\\\$(Build.BuildNumber)](<\TT-FS01\Builds\Securitas\EmployeePortal$(Build.BuildNumber)>) |

### Tweak "Publish Build Artifacts" task (e.g. to avoid extraneous "drop" folder)

| **Task: Publish Artifact...** |     |
| ----------------------------- | --- |
| Artifact Name                 | .   |

### Change "Copy Files" task to only include "Deployment Files" and "Docs"

<table>
<thead>
<th>
<p><strong>Task: Copy Files...</strong></p>
</th>
<th>
</th>
</thead>
<tr>
<td valign='top'>
<p>Contents</p>
</td>
<td valign='top'>
<p>Code\\Deployment Files\\**<br />
Docs\\**</p>
</td>
</tr>
</table>

### Split "Copy Files" task into two tasks

> **Comment**
>
> Split "Copy Files" task into two tasks -- so that "Deployment Files" folder is copied side-by-side with "Docs" folder (rather than "Code\\Deployment Files" and "Docs")

| **New Task: Copy Files** |  |
| --- | --- |
| Display name | Copy Docs to: \$(Build.ArtifactStagingDirectory) |
| Source Folder | \$(Build.SourcesDirectory) |
| Contents | Docs\\\*\* |
| Target Folder | \$(Build.ArtifactStagingDirectory) |
| Run this task | Even if a previous task has failed, unless the build was canceled |

### Tweak variables (e.g. change "release" to "Release")

| **Variables**      |         |
| ------------------ | ------- |
| BuildConfiguration | Release |
| BuildPlatform      | Any CPU |

### Build both Debug and Release configurations

| **Variables**      |               |
| ------------------ | ------------- |
| BuildConfiguration | Debug,Release |

| **Options**         |                    |
| ------------------- | ------------------ |
| Multi-configuration | Enabled            |
| Multipliers         | BuildConfiguration |

### Revert to only building Release configuration

> **Comment**
>
> Revert to only building Release configuration (it takes a long time to build both configurations and we currently don't deploy Debug builds anywhere)

### Set build number (from AssemblyVersionInfo.cs file)

<table>
<thead>
<th>
<p><strong>New Task: PowerShell</strong></p>
</th>
<th>
</th>
</thead>
<tr>
<td valign='top'>
<p>Display name</p>
</td>
<td valign='top'>
<p>Set build number</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Type</p>
</td>
<td valign='top'>
<p>Inline Script</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Inline Script</p>
</td>
<td valign='top'>
<p>\$assemblyVersion = .\\Get-AssemblyFileVersion.ps1 AssemblyVersionInfo.cs</p>
<p>Write-Host &quot;##vso[build.updatebuildnumber]\$assemblyVersion&quot;</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Working folder</p>
</td>
<td valign='top'>
<p>Code</p>
</td>
</tr>
</table>

### Increment the assembly version (for the next build)

| **New Task: PowerShell** |                                      |
| ------------------------ | ------------------------------------ |
| Display name             | Increment assembly version           |
| Type                     | File Path                            |
| Script Path              | Code\\Increment Assembly Version.ps1 |
| Arguments                | -Verbose                             |
| Working folder           | Code\\                               |

### Throw error when a build already exists for the specified assembly version

| **Task: Increment assembly version** |       |
| ------------------------------------ | ----- |
| Enabled                              | false |

<table>
<thead>
<th>
<p><strong>Task: Set build number</strong></p>
</th>
<th>
</th>
</thead>
<tr>
<td valign='top'>
<p>Display name</p>
</td>
<td valign='top'>
<p>Validate and set build number</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Inline Script</p>
</td>
<td valign='top'>
<p>\$assemblyVersion = .\\Get-AssemblyFileVersion.ps1 AssemblyVersionInfo.cs</p>
<p>\$builds = .\\Get-TfsBuilds.ps1 -BuildNumberFilter \$assemblyVersion</p>
<p>If (\$builds -eq \$null)<br />
{<br />
    Write-Host &quot;##vso[build.updatebuildnumber]\$assemblyVersion&quot;<br />
}<br />
Else<br />
{<br />
    throw &quot;The build number (\$assemblyVersion) already exists.&quot;<br />
}</p>
</td>
</tr>
</table>

### Increment assembly version using TFS Rest API

| **Task: Increment assembly version** |                      |
| ------------------------------------ | -------------------- |
| Arguments                            | -UseRestApi -Verbose |
| Enabled                              | true                 |

### Create bug on build failure

| **Options**                 |         |
| --------------------------- | ------- |
| Create work item on failure | Enabled |
| Type                        | Bug     |

### Change "Copy Files" tasks to only run when all previous tasks have succeeded
