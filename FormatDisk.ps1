Get-Disk | Where-Object PartitionStyle -eq "RAW" | Initialize-Disk -PartitionStyle MBR -Confirm:$False -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$False

New-LocalGroup ServiceFabricAllowedUsers
New-Item -ItemType directory -Path D:\source
$acl = Get-Acl D:source
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("ServiceFabricAllowedUsers","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl D:source $acl
