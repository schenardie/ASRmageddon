<#
    MIT License

    Copyright (c) Microsoft Corporation.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE
#>


Param([Parameter(Mandatory = $false)][String[]]$URL = "https://raw.githubusercontent.com/schenardie/ASRmageddon/main/V2/AppList.json")

$Programs = Invoke-RestMethod -Uri "$URL" -Headers @{"Cache-Control" = "no-cache" }
$Programs = $Programs | Select-Object -Skip 1
$LogFileName = "ShortcutRepairs.log";
$LogFilePath = "$env:temp\$LogFileName";

Function Log {
    param($message);
    $currenttime = Get-Date -format u;
    $outputstring = "[" + $currenttime + "] " + $message;
    $outputstring | Out-File $LogFilepath -Append;
}

Function LogAndConsole($message) {
    Write-Host $message -ForegroundColor Green
    Log $message
}

Function LogErrorAndConsole($message) {
    Write-Host $message -ForegroundColor Red
    Log $message
}

Function CopyAclFromOwningDir($path) {
    $base_path = Split-Path -Path $path
    $acl = Get-Acl $base_path
    $group = New-Object System.Security.Principal.NTAccount("Builtin", "Administrators")
    $acl.SetOwner($group)
    Set-Acl $path $acl
}

# Validate elevated privileges
LogAndConsole "Starting LNK rescue"
$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$p = New-Object System.Security.Principal.WindowsPrincipal($id)
if (!($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) -Or ($id.Name -like "NT AUTHORITY\SYSTEM"))) {
    LogErrorAndConsole "Not running from an elevated context"
    throw "Please run this script from an elevated PowerShell as Admin or as System"
    exit
}

# Check for shortcuts in Start Menu, if program is available and the shortcut isn't... Then recreate the shortcut
$success = 0
$failures = 0
LogAndConsole "Enumerating installed software against Shortcut list"
$programs.GetEnumerator() | ForEach-Object {
    try {
        if ((Test-Path -Path $($_.TargetPath)) -and (-not (Test-Path -Path $($_.Fullname))   ))
            { 
                    $appname = split-path $($_.TargetPath) -leaf
                    LogAndConsole ("Shortcut for {0} not found in Start Menu, creating it now." -f $appname)
                    $target = "$($_.TargetPath)"
                    $shortcut_path = "$($_.Fullname)"
                    $description = "$($_.Description)"
                    $workingdirectory = "$($_.WorkingDirectory)"
                    $WshShell = New-Object -ComObject WScript.Shell
                    $Shortcut = $WshShell.CreateShortcut($shortcut_path)
                    $Shortcut.TargetPath = $target
                    $Shortcut.Description = $description
                    $shortcut.WorkingDirectory = $workingdirectory
                    $Shortcut.Save()
                    Start-Sleep -Seconds 1			# Let the LNK file be backed to disk
                    LogAndConsole "Copying ACL from owning folder"
                    CopyAclFromOwningDir $shortcut_path
                    $success += 1
                         
            }

        }
        catch {
            $failures += 1
            LogErrorAndConsole "Exception: $_"
        }
    }

    LogAndConsole "Finished with $failures failures and $success successes"