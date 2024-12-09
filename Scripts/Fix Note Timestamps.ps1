function FixNoteTimestamp([string] $path) {
    [int] $lineNumber = 3

    $content = Get-Content -Path $path
    $content |
    ForEach-Object {
        [bool] $foundTimestamp = $false

        if ($_.ReadCount -eq $lineNumber) {
            [DateTime] $noteDate = New-Object DateTime

            [bool] $success = [DateTime]::TryParse($_, [ref]$noteDate)

            If ($success -eq $true) {
                $foundTimestamp = $true
            }
        }

        if ($foundTimestamp -eq $true) {
            [string] $modifiedLine = $_ + '\'

            $modifiedLine
        }
        else {
            $_
        } 
    } |
    Set-Content $path
}

[string] $rootPath = Resolve-Path ($PSScriptRoot + '\..')

Get-ChildItem -Recurse $rootPath "*.md" |
ForEach-Object {
    FixNoteTimestamp $_.FullName
}