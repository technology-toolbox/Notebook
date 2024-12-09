# Azure Dev/Test

Friday, March 15, 2019\
6:29 AM

## Install the Azure PowerShell module

### Reference

**Install the Azure PowerShell module**\
From <[https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-1.5.0](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-1.5.0)>

```PowerShell
Install-Module -Name Az -AllowClobber

Import-Module Az
WARNING: Both Az and AzureRM modules were detected on this machine. Az and AzureRM modules cannot be imported in the same session or
used in the same script or runbook. If you are running PowerShell in an environment you control you can use the 'Uninstall-AzureRm'
cmdlet to remove all AzureRm modules from your machine. If you are running in Azure Automation, take care that none of your runbooks
import both Az and AzureRM modules. More information can be found here: https://aka.ms/azps-migration-guide
```

```PowerShell
cls
```

### # Sign in

```PowerShell
# Connect to Azure with a browser sign in token

Connect-AzAccount
```

### Deploy resource template

#### Reference

**Deploy resources with Resource Manager templates and Azure PowerShell**\
From <[https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy?view=azps-1.5.0](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy?view=azps-1.5.0)>

```PowerShell
cls
```

#### # Create resource group

```PowerShell
$resourceGroupName = 'techtoolbox-devtest-02'
$location = 'West US 2'

New-AzResourceGroup -Name $resourceGroupName -Location $location
New-AzResourceGroup : The current subscription type is not permitted to perform operations on any provider namespace. Please use a
different subscription.
At line:1 char:1
+ New-AzResourceGroup -Name $resourceGroupName -Location $location
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : CloseError: (:) [New-AzResourceGroup], CloudException
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.NewAzureResourceGroupCmdlet

Get-AzSubscription

Name                             Id                                   TenantId                             State
----                             --                                   --------                             -----
Access to Azure Active Directory ********-f2c1-4f9d-ac7f-{redacted} ********-b76f-400c-ba19-{redacted} Enabled
Visual Studio Ultimate with MSDN ********-fdf5-4fd0-b21b-{redacted} ********-b76f-400c-ba19-{redacted} Enabled

Set-AzContext -SubscriptionName 'Visual Studio Ultimate with MSDN'

New-AzResourceGroup -Name $resourceGroupName -Location $location
```

```PowerShell
cls
```

#### # Deploy resources

```PowerShell
$templateFile = "C:\NotBackedUp\techtoolbox\Infrastructure\Main\Azure\DevTest\deploy.json"
$templateParameterFile = "C:\NotBackedUp\techtoolbox\Infrastructure\Main\Azure\DevTest\deploy.parameters.json"

New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile $templateFile `
    -TemplateParameterFile $templateParameterFile

New-AzResourceGroupDeployment : 7:58:58 AM - Resource Microsoft.Insights/alertrules 'LongHttpQueue hostingplane2ehfgjq57enc' failed
with message '{
  "code": "UnsupportedMetric",
  "message": "The metric with namespace '' and name 'HttpQueueLength' is not supported for this resource id '/subscriptions/********-fdf 5-4fd0-b21b-{redacted}/resourceGroups/techtoolbox-devtest-02/providers/Microsoft.Web/serverfarms/hostingplane2ehfgjq57enc'."
}'
At line:1 char:1
+ New-AzResourceGroupDeployment `
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [New-AzResourceGroupDeployment], Exception
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.NewAzureResourceGroupDeploymentCmdlet

New-AzResourceGroupDeployment : 7:58:58 AM - Resource Microsoft.Insights/alertrules 'CPUHigh hostingplane2ehfgjq57enc' failed with
message '{
  "code": "UnsupportedMetric",
  "message": "The metric with namespace '' and name 'CpuPercentage' is not supported for this resource id '/subscriptions/********-fdf5- 4fd0-b21b-{redacted}/resourceGroups/techtoolbox-devtest-02/providers/Microsoft.Web/serverfarms/hostingplane2ehfgjq57enc'."
}'
At line:1 char:1
+ New-AzResourceGroupDeployment `
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [New-AzResourceGroupDeployment], Exception
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.NewAzureResourceGroupDeploymentCmdlet

New-AzResourceGroupDeployment : 7:58:58 AM - Resource Microsoft.Sql/servers 'sqlservere2ehfgjq57enc' failed with message '{
  "status": "Failed",
  "error": {
    "code": "ResourceDeploymentFailure",
    "message": "The resource operation completed with terminal provisioning state 'Failed'.",
    "details": [
      {
        "code": "PasswordNotComplex",
        "message": "Password validation failed. The password does not meet policy requirements because it is not complex enough."
      }
    ]
  }
}'
At line:1 char:1
+ New-AzResourceGroupDeployment `
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [New-AzResourceGroupDeployment], Exception
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.NewAzureResourceGroupDeploymentCmdlet

New-AzResourceGroupDeployment : 7:58:58 AM - Password validation failed. The password does not meet policy requirements because it is
not complex enough.
At line:1 char:1
+ New-AzResourceGroupDeployment `
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [New-AzResourceGroupDeployment], Exception
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.NewAzureResourceGroupDeploymentCmdlet

New-AzResourceGroupDeployment : 8:00:06 AM - Template output evaluation skipped: at least one resource deployment operation failed.
Please list deployment operations for details. Please see https://aka.ms/arm-debug for usage details.
At line:1 char:1
+ New-AzResourceGroupDeployment `
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [New-AzResourceGroupDeployment], Exception
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.NewAzureResourceGroupDeploymentCmdlet

New-AzResourceGroupDeployment : 8:00:06 AM - Template output evaluation skipped: at least one resource deployment operation failed.
Please list deployment operations for details. Please see https://aka.ms/arm-debug for usage details.
At line:1 char:1
+ New-AzResourceGroupDeployment `
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [New-AzResourceGroupDeployment], Exception
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.NewAzureResourceGroupDeploymentCmdlet



DeploymentName          : deploy
ResourceGroupName       : techtoolbox-devtest-02
ProvisioningState       : Failed
Timestamp               : 3/15/2019 2:00:02 PM
Mode                    : Incremental
TemplateLink            :
Parameters              :
                          Name                             Type                       Value
                          ===============================  =========================  ==========
                          skuName                          String                     F1
                          skuCapacity                      Int                        1
                          sqlAdministratorLogin            String                     GEN-UNIQUE-8
                          sqlAdministratorLoginPassword    SecureString
                          location                         String                     westus2

Outputs                 :
DeploymentDebugLogLevel :
```
