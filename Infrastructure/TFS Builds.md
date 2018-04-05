# TFS Builds

Wednesday, April 4, 2018
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
> Specify solution file to build (since using "**\\*.sln" can be problematic with node_modules folder)

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

| **Task: Build solution...** |                                                                                                                                                                             |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|                           |                                                                                                                                                                             |
| MSBuild Arguments         | /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true /p:PackageLocation="\$(Build.ArtifactStagingDirectory)\\\\" |

### Modify "Get sources" task to clean all build directories

| **Task: Get sources** |                       |
| --------------------- | --------------------- |
| Clean                 | true                  |
| Clean options         | All build directories |

### Update drop location

> **Comment**
>
> Change drop location to file share and add "\$(BuildConfiguration)" to package path

| **Task: Build solution...** |                                                                                                                                                                                                       |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| MSBuild Arguments         | /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true /p:PackageLocation="\$(Build.ArtifactStagingDirectory)\\\\\$(BuildConfiguration)\\\\" |

| **Task: Publish Artifact...** |                                                                                                                                         |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Artifact Type               | File share                                                                                                                              |
| Path                        | [\\\\TT-FS01\\Builds\\Securitas\\EmployeePortal\\\$(Build.BuildNumber)](\\TT-FS01\Builds\Securitas\EmployeePortal\$(Build.BuildNumber)) |

### Tweak "Publish Build Artifacts" task (e.g. to avoid extraneous "drop" folder)

| **Task: Publish Artifact...** |   |
| --------------------------- | - |
| Artifact Name               | . |

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
