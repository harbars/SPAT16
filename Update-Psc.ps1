#region PARAMS
param (
    [Bool]$debug
) 
#endregion PARAMS

$path = "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\bin\psconfig.exe"

Write-Output "$(Get-Date -Format T) : Upgrading (B2B) on $env:COMPUTERNAME..."
if ($debug) {
    & $path -cmd upgrade -inplace b2b -force
}
else {
    & $path -cmd upgrade -inplace b2b -force | Out-Null
}
#EOF