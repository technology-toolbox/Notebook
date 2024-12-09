# Storage

Tuesday, March 6, 2018\
2:18 AM

```PowerShell
robocopy E:\ '\\tt-hv02c\d$\NotBackedUp\TT-HV02A\E' /E /J /XD "System Volume Information" /W:1 /R:1

robocopy E:\ '\\tt-hv02c\d$\NotBackedUp\TT-HV02B\E' /E /J /XD "System Volume Information" /W:1 /R:1
```
