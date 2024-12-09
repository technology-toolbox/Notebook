# EXT-WIN8

Tuesday, March 03, 2015\
10:20 AM

Error trying to remote PowerShell from EXT-DC03:

```Text
PS C:\Windows\system32> Enter-PSSession EXT-WIN8
Enter-PSSession : Connecting to remote server EXT-WIN8 failed with the following error message : WinRM cannot process the request. The following error occurred while using Kerberos authentication: Cannot find the computer EXT-WIN8.
Verify that the computer exists on the network and that the name provided is spelled correctly. For more information, see the about_Remote_Troubleshooting Help topic.
At line:1 char:1
+ Enter-PSSession EXT-WIN8
+ ~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidArgument: (EXT-WIN8:String) [Enter-PSSession], PSRemotingTransportException
    + FullyQualifiedErrorId : CreateRemoteRunspaceFailed
```

Error trying to RDP from EXT-DC03 (using **EXTRANET\\jjameson-admin** account):

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F7/343340796F3AA154F750FFCDA26409E0F80A37F7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/4D46BAF3094157811BA7CABB10BD8BB8EC7F0C94.png)

Workaround: Use **WIN8\\foo** account instead
