  Get-Disk |
    Where-Object { !$_.Location.Contains("LUN 0") } |
    Where-Object PartitionStyle -eq "RAW" |
    Initialize-Disk -PartitionStyle MBR -Confirm:$False -PassThru |
    New-Partition -AssignDriveLetter -UseMaximumSize |
    Format-Volume -FileSystem NTFS -Confirm:$False
    
    Add-Content -Path 'C:\ProgramData\Docker\config\daemon.json' -Value '{ "data-root": "Z:\\dockerdata" }' 
