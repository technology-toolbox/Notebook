# Windows Update Slots

Tuesday, January 23, 2018\
11:33 AM

```PowerShell
Function CreateResultObject([string] $ComputerName, [string] $Slot)
{
    $result = New-Object -TypeName PSObject

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name Computer `
        -Value $ComputerName

    If ($Slot)
    {
        $result | Add-Member `
            -MemberType NoteProperty `
            -Name Slot `
            -Value ([int] $Slot)
    }
    Else
    {
        $result | Add-Member `
            -MemberType NoteProperty `
            -Name Slot `
            -Value $null
    }

    $result
}

Get-Content "\\TT-FS01\Users$\jjameson-admin\Desktop\Computer list for Windows Update.txt" |
    foreach {
        $computerName = $_

        $groups = Get-ADPrincipalGroupMembership ($computerName + '$') |
            where { $_.Name -like 'Windows Update - Slot *' }

        If ($groups -eq $null)
        {
            CreateResultObject $computerName $null
        }
        Else
        {
            $groups |
                foreach {
                    $slot = $_.Name.Substring('Windows Update - Slot '.Length)

                    CreateResultObject $computerName $slot
                }
        }
    } |
    Format-Table -AutoSize
```
