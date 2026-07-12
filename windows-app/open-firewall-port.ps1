# Run this in an elevated (Administrator) PowerShell window if the Windows
# Firewall prompt never appeared, was dismissed, or auto-discovery still
# isn't working after installing ViGEmBus.
#
# Usage:
#   Right-click this file -> "Run with PowerShell" (as Administrator)
# or from an admin PowerShell prompt:
#   .\open-firewall-port.ps1

$port = 47998
$ruleName = "Virtual Gamepad (UDP $port)"

if (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue) {
    Write-Host "Rule already exists - removing old one first..."
    Remove-NetFirewallRule -DisplayName $ruleName
}

New-NetFirewallRule -DisplayName $ruleName `
    -Direction Inbound `
    -Protocol UDP `
    -LocalPort $port `
    -Action Allow `
    -Profile Domain,Private,Public | Out-Null

Write-Host "Done. Inbound UDP port $port is now allowed on all network profiles."
Write-Host "If your phone still can't auto-discover this PC, check whether your"
Write-Host "router has 'AP isolation' / 'client isolation' / a guest network"
Write-Host "enabled - these block phone-to-PC traffic entirely and are a router"
Write-Host "setting, not something this app can work around. Manual IP entry in"
Write-Host "the phone app still works even with isolation enabled, as long as"
Write-Host "the port itself isn't blocked."
