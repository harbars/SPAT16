# disables the loopback check

$lsaPath = "HKLM:\System\CurrentControlSet\Control\Lsa"
$lsaPathValue = Get-ItemProperty -path $lsaPath
If (-not ($lsaPathValue.DisableLoopbackCheck -eq "1"))
{
    New-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa -Name "DisableLoopbackCheck" -value "1" -PropertyType dword -Force | Out-Null
    Write-Warning "A server restart on ($env:ComputerName) is needed for the loopback setting to take effect." 
}
Write-Output "$(Get-Date -Format T) : Loopback Check Disabled on $env:ComputerName"