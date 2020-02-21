# Office 365

Thursday, December 6, 2018
4:16 AM

## Settings

### Organization profile

#### Navigation bar customization

| Theme Setting      | Value  |
| ------------------ | ------ |
| Accent color       | 3C78C3 |
| Nav bar background | 1E4173 |
| Text and icons     | FFFFFF |

## Configure multi-factor authentication

### References

**Allow MFA users to create App passwords for Office client apps**\
From <[https://docs.microsoft.com/en-us/office365/admin/security-and-compliance/set-up-multi-factor-authentication?view=o365-worldwide](https://docs.microsoft.com/en-us/office365/admin/security-and-compliance/set-up-multi-factor-authentication?view=o365-worldwide)>

**Connect to Exchange Online PowerShell**\
From <[https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/connect-to-exchange-online-powershell/connect-to-exchange-online-powershell?view=exchange-ps](https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/connect-to-exchange-online-powershell/connect-to-exchange-online-powershell?view=exchange-ps)>

### Allow MFA users to create App passwords for Office client apps

> **Note**
>
> All Office 2016 client applications support MFA through the use of the Active Directory Authentication Library (ADAL). This means that app passwords aren't required for Office 2016 clients. However, if you find that this is not the case, make sure your Office 365 subscription is enabled for ADAL. Connect to [Exchange Online PowerShell](Exchange Online PowerShell) and run the following command:
>
> ```PowerShell
> Get-OrganizationConfig | Format-Table name, *OAuth*
> ```
>
> From <[https://docs.microsoft.com/en-us/office365/admin/security-and-compliance/set-up-multi-factor-authentication?view=o365-worldwide](https://docs.microsoft.com/en-us/office365/admin/security-and-compliance/set-up-multi-factor-authentication?view=o365-worldwide)>

#### Connect to Exchange Online PowerShell

```PowerShell
$UserCredential = Get-Credential jjameson-admin@technologytoolbox.com

$Session = New-PSSession `
    -ConfigurationName Microsoft.Exchange `
    -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
    -Credential $UserCredential `
    -Authentication Basic `
    -AllowRedirection

Import-PSSession $Session -DisableNameChecking

Get-OrganizationConfig | Format-Table name, *OAuth*
```

```Text
Name                        OAuth2ClientProfileEnabled
----                        --------------------------
techtoolbox.onmicrosoft.com                      False
```

```PowerShell
Set-OrganizationConfig -OAuth2ClientProfileEnabled:$true

Get-OrganizationConfig | Format-Table name, *OAuth*
```

```Text
Name                        OAuth2ClientProfileEnabled
----                        --------------------------
techtoolbox.onmicrosoft.com                       True
```

```PowerShell
Remove-PSSession $Session
```
