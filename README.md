## Intro
After the ASRmageddon hit I quickly realised the script provided by Microsoft would be missing a lot of executables, and to update tha list would be quite a bit of work with dozens of customers. So the idea of creating a dynamic, public list came to mind. The script is packaged as a Win32App that reads the Log file generated to Microsoft and compares with the first line of the AppList.json, if the date is older than the one on the json, it forces to run again and evaluate newly added apps.

## Deploying
To deploy to intune simply use the FixShortcuts.intunewin using the below Install Cmd line.
```%windir%\sysnative\windowspowershell\v1.0\powershell.exe -executionPolicy bypass -windowstyle hidden -file .\FixShortcuts.ps1 -url https://raw.githubusercontent.com/schenardie/ASRmageddon/main/AppList.json```
For detection you can use the Detect.ps1 script 

**Note** this script is hardcoded to my repository, if you plan to use your own please udpate the detection script it to match the one used on the install cmd line (-url) and make sure you always update the first entry by running ```Get-Date -Format u```