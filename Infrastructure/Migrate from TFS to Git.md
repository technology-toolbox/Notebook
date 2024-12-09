# Migrate from TFS to Git

Wednesday, August 14, 2019\
10:34 AM

## Reference

**TargetInvocationException during clone**\
From <[https://www.bountysource.com/issues/41391564-targetinvocationexception-during-clone](https://www.bountysource.com/issues/41391564-targetinvocationexception-during-clone)>

```PowerShell
cls
```

## # Configure e-mail and name for Git

```PowerShell
git config --global user.email "jjameson@technologytoolbox.com"
git config --global user.name "Jeremy Jameson"
```

```PowerShell
cls
```

## # Install Chocolatey

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

### Reference

**Installing Chocolatey**\
From <[https://chocolatey.org/docs/installation](https://chocolatey.org/docs/installation)>

```PowerShell
cls
```

## # Install git-tfs

```PowerShell
choco install gittfs
```

```PowerShell
cls
```

## # Clone branch from TFS to Git repository

```PowerShell
git tfs clone https://dev.azure.com/techtoolbox $/Infrastructure/Main/MDT-Build$
```

```PowerShell
clear
```

## # Replace author

```PowerShell
#!/bin/sh

git filter-branch --env-filter '

OLD_EMAIL="jjameson-admin@technologytoolbox.com"
CORRECT_NAME="Jeremy Jameson"
CORRECT_EMAIL="jjameson@technologytoolbox.com"

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags
```

### Reference

**Changing author info**\
From <[https://help.github.com/en/articles/changing-author-info](https://help.github.com/en/articles/changing-author-info)>
