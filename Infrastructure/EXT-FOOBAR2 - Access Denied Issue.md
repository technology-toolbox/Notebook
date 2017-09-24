# Access Denied Issue

Sunday, September 24, 2017
7:52 AM

```PowerShell
Enable-SharePointCmdlets

$webApp = Get-SPWebApplication $env:SECURITAS_CLIENT_PORTAL_URL
$webApp.Properties.Remove("portalsuperuseraccount")
$webApp.Properties.Remove("portalsuperreaderaccount")
$webApp.Update()

iisreset
```
