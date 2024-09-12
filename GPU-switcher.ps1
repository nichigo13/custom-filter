Unregister-Event -SourceIdentifier graphicsCardChanged

function dGPUSwap
{ 
#Set DGPU and EGPU by name 
$dgpu_name = "Intel(R) Iris(R) Xe Graphics"
$egpu_name = "AMD Radeon RX 6700 XT"

Write-Host "Checking eGPU presence..."

#Testing eGPU presence
$condition1 = (Get-PnpDevice | where {($_.friendlyname) -like "$($egpu_name)" -and ($_.status) -like "Ok"}) -ne $null
$condition2 = (Get-PnpDevice | where {($_.friendlyname) -like "$($egpu_name)" -and ($_.status) -like "Ok"}) -eq $null

#Get DGPU en EGPU Ids and status
$dgpu_id = (Get-PnpDevice | where {$_.friendlyname -like "$($dgpu_name)*"} | ft InstanceId -HideTableHeaders | out-string -Width 640).trim()
$dgpu_status = (Get-PnpDevice -InstanceID $dgpu_id | ft Status -HideTableHeaders | out-string -Width 640).trim()
$egpu_id = (Get-PnpDevice | where {$_.friendlyname -like "$($egpu_name)*"-and ($_.status) -like "Ok"} | ft InstanceId -HideTableHeaders | out-string -Width 640).trim()
$egpu_status = (Get-PnpDevice -InstanceID $egpu_id | ft Status -HideTableHeaders | out-string -Width 640).trim()

#Debug lines
#Write-Host "dgpu : $dgpu_id"
#Write-Host "dgpu status : $dgpu_status"
#Write-Host "egpu : $egpu_id"
#Write-Host "egpu status : $egpu_status"
#Write-Host "eventType : $eventType"
#Write-Host "condition1 : $condition1"
#Write-Host "condition2 : $condition2"

#If eGPU detected
if ($condition1) {
Write-Host "eGPU detected"

#If dGPU currently active
if($dgpu_status -ne "Error") {
Disable-PnpDevice -InstanceID $dgpu_id -Confirm:$false
Write-Host "dGPU disabled"
}
}

#If eGPU not detected
if ($condition2) {
Write-Host "egpu not detected"

#If dGPU currently inactive
if($dgpu_status -ne "OK") {
Enable-PnpDevice -InstanceID $dgpu_id -Confirm:$false
Write-Host "dGPU enabled"
}
}
}


Write-Host "Script launched !"

#Run function to enable or disable dGPU at session start
dGPUSwap

Register-WmiEvent -Class Win32_DeviceChangeEvent -SourceIdentifier graphicsCardChanged
do{

$newEvent = Wait-Event -SourceIdentifier graphicsCardChanged
$eventType = $newEvent.SourceEventArgs.NewEvent.EventType
$eventTypeName = switch($eventType)
{
1 {"Configuration changed"}
2 {"Device arrival"}
3 {"Device removal"}
4 {"docking"}
}

Write-Host "Configuration changed"

#Run function to enable or disable dGPU
dGPUSwap

Remove-Event -SourceIdentifier graphicsCardChanged

} while (1-eq1) #Loop until next event

Unregister-Event -SourceIdentifier graphicsCardChanged