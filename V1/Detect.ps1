try {
    $Programs = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/schenardie/ASRmageddon/main/AppList.json" -Headers @{"Cache-Control"="no-cache"}
    $LastUpdated = ($Programs | Select-Object -First 1).Value
    if (Test-Path $env:temp\ShortcutRepairs.log) {
        $LastRun = [regex]::Matches((Get-Content $env:temp\ShortcutRepairs.log -Tail 1) , '(?<=\[).+?(?=\])').Value
        if ( (Get-Date "$LastUpdated") -lt (Get-Date "$LastRun")) {
            return "Detected"
        }
    }
}
Catch { exit }