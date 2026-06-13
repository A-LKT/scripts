# hw-spec.ps1 — Print core hardware specs, optionally save to file
# Usage: .\hw-spec.ps1 [-Save]
param([switch]$Save)

function Sep { "-" * 52 }
function Row($label, $value) { "  {0,-22} {1}" -f ($label + ":"), $value }

$lines = @()
$lines += "=" * 52
$lines += "  HARDWARE SPEC REPORT"
$lines += "  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$lines += "=" * 52

# --- System ---
$cs   = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$lines += ""
$lines += "[ SYSTEM ]"
$lines += Sep
$lines += Row "Manufacturer"   $cs.Manufacturer
$lines += Row "Model"          $cs.Model
$lines += Row "BIOS Version"   "$($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)"

# --- OS ---
$os = Get-CimInstance Win32_OperatingSystem
$lines += ""
$lines += "[ OPERATING SYSTEM ]"
$lines += Sep
$lines += Row "OS"             $os.Caption
$lines += Row "Version"        $os.Version
$lines += Row "Build"          $os.BuildNumber
$lines += Row "Architecture"   $os.OSArchitecture

# --- CPU ---
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$lines += ""
$lines += "[ CPU ]"
$lines += Sep
$lines += Row "Name"           $cpu.Name.Trim()
$lines += Row "Cores / Threads" "$($cpu.NumberOfCores) cores / $($cpu.NumberOfLogicalProcessors) threads"
$lines += Row "Base Clock"     "$([math]::Round($cpu.MaxClockSpeed / 1000, 2)) GHz"
$lines += Row "Socket"         $cpu.SocketDesignation

# --- RAM ---
$ramModules = Get-CimInstance Win32_PhysicalMemory
$totalRamGB  = [math]::Round(($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB, 0)
$ramSpeed    = ($ramModules | Select-Object -First 1).Speed
$ramType     = switch (($ramModules | Select-Object -First 1).MemoryType) {
    20 { "DDR" } 21 { "DDR2" } 24 { "DDR3" } 26 { "DDR4" } 34 { "DDR5" } default { "DDR4" }
}
# SMBIOSMemoryType is more reliable for modern DDR
$smbType = ($ramModules | Select-Object -First 1).SMBIOSMemoryType
$ramType = switch ($smbType) {
    26 { "DDR4" } 27 { "LPDDR3" } 28 { "LPDDR3" } 29 { "DDR4" } 30 { "LPDDR4" } 34 { "DDR5" } 35 { "LPDDR5" } default { $ramType }
}
$slots = $ramModules.Count
$lines += ""
$lines += "[ RAM ]"
$lines += Sep
$lines += Row "Total"          "${totalRamGB} GB"
$lines += Row "Type / Speed"   "$ramType @ ${ramSpeed} MHz"
$lines += Row "Modules"        "$slots stick(s) of $([math]::Round($totalRamGB / $slots, 0)) GB each"
foreach ($m in $ramModules) {
    $gb   = [math]::Round($m.Capacity / 1GB, 0)
    $mfr  = if ($m.Manufacturer) { $m.Manufacturer.Trim() } else { "Unknown" }
    $part = if ($m.PartNumber)   { $m.PartNumber.Trim()   } else { "" }
    $lines += Row "  Slot $($m.DeviceLocator)" "${gb} GB  $mfr  $part"
}

# --- Motherboard ---
$mb = Get-CimInstance Win32_BaseBoard
$lines += ""
$lines += "[ MOTHERBOARD ]"
$lines += Sep
$lines += Row "Manufacturer"   $mb.Manufacturer
$lines += Row "Model"          $mb.Product
$lines += Row "Version"        $mb.Version

# --- GPU(s) ---
$gpus = Get-CimInstance Win32_VideoController | Where-Object { $_.AdapterRAM -gt 0 -or $_.Name -notmatch "Microsoft|Basic" }
if (-not $gpus) { $gpus = Get-CimInstance Win32_VideoController }
$lines += ""
$lines += "[ GPU ]"
$lines += Sep
foreach ($g in $gpus) {
    $vramGB = if ($g.AdapterRAM) { "$([math]::Round($g.AdapterRAM / 1GB, 0)) GB" } else { "N/A" }
    $lines += Row "Name"         $g.Name
    $lines += Row "  VRAM"       $vramGB
    $lines += Row "  Driver"     $g.DriverVersion
    $lines += Row "  Resolution" "$($g.CurrentHorizontalResolution) x $($g.CurrentVerticalResolution)"
}

# --- Storage ---
$disks = Get-CimInstance Win32_DiskDrive | Sort-Object Index
$lines += ""
$lines += "[ STORAGE ]"
$lines += Sep
foreach ($d in $disks) {
    $sizeGB = [math]::Round($d.Size / 1GB, 0)
    $media  = if ($d.MediaType) { $d.MediaType } else { "Unknown" }
    $lines += Row "Disk $($d.Index)"  "${sizeGB} GB  |  $($d.Model.Trim())"
    $lines += Row "  Interface"  "$($d.InterfaceType)  ($media)"
}

# --- Display ---
$monitors = Get-CimInstance WmiMonitorID -Namespace root\wmi -ErrorAction SilentlyContinue
if ($monitors) {
    $lines += ""
    $lines += "[ DISPLAY ]"
    $lines += Sep
    foreach ($mon in $monitors) {
        $name = ([System.Text.Encoding]::ASCII.GetString(
            ($mon.UserFriendlyName | Where-Object { $_ -ne 0 }))).Trim()
        $mfr  = ([System.Text.Encoding]::ASCII.GetString(
            ($mon.ManufacturerName | Where-Object { $_ -ne 0 }))).Trim()
        $yr   = $mon.YearOfManufacture
        $lines += Row "Monitor" "$name  ($mfr, $yr)"
    }
}

# --- Network adapters (physical only) ---
$nics = Get-CimInstance Win32_NetworkAdapter |
        Where-Object { $_.PhysicalAdapter -eq $true -and $_.MACAddress -ne $null }
if ($nics) {
    $lines += ""
    $lines += "[ NETWORK ]"
    $lines += Sep
    foreach ($n in $nics) {
        $lines += Row $n.AdapterType $n.Name
    }
}

$lines += ""
$lines += "=" * 52

# Output to console
$lines | ForEach-Object { Write-Host $_ }

# Save to file if -Save flag used
if ($Save) {
    $ts   = Get-Date -Format "yyyy-MM-dd_HHmm"
    $host_ = $env:COMPUTERNAME
    $path = "$PSScriptRoot\hw-spec_${host_}_${ts}.txt"
    $lines | Out-File -FilePath $path -Encoding utf8
    Write-Host ""
    Write-Host "Saved to: $path" -ForegroundColor Green
}
