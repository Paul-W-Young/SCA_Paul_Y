<#
.SYNOPSIS
Restart one or more remote Windows computers.

.DESCRIPTION
This script sends a restart command to remote computers using Restart-Computer. It optionally accepts alternate credentials and waits for the remote computer to respond after reboot.

.EXAMPLE
.\Restart-RemoteComputer.ps1 -ComputerName "lon-svr1"

.EXAMPLE
.\Restart-RemoteComputer.ps1 -ComputerName "lon-svr1" -Force
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string[]]$ComputerName,        # Target computer name(s) to restart.

    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]$Credential,  # Optional credentials to use.

    [Parameter(Mandatory=$false)]
    [switch]$Force,                # Force restart even if applications are open.

    [Parameter(Mandatory=$false)]
    [int]$TimeoutSeconds = 300     # How long to wait for the restart to complete.
)

# Show the user what computer(s) are being targeted.
Write-Host "Remote restart starting for: $($ComputerName -join ', ')" -ForegroundColor Cyan

try {
    # Build a splatted parameter set for Restart-Computer.
    $params = @{
        ComputerName   = $ComputerName
        Credential     = $Credential
        Force          = $Force.IsPresent
        Wait           = $true                  # Wait for the restart to complete.
        For            = 'PowerShell'          # Wait using PowerShell remoting.
        Timeout        = $TimeoutSeconds       # Timeout in seconds.
        Confirm        = $false                 # Do not prompt for confirmation.
        ErrorAction    = 'Stop'                # Stop on the first error.
    }

    Restart-Computer @params

    Write-Host "Restart command sent successfully." -ForegroundColor Green
}
catch {
    # Show the error message if the restart fails.
    Write-Host "Failed to restart one or more computers:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    exit 1
}
