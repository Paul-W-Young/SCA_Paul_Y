<#
.SYNOPSIS
Enumerates expired Active Directory user accounts.

.DESCRIPTION
Uses the ActiveDirectory module to find all user accounts whose account expiration date has passed.

#>
[CmdletBinding()]
param(
    [switch]$IncludeDisabled,
    [switch]$ExportCsv,
    [string]$CsvPath = "$PSScriptRoot\ExpiredUsers.csv"
)

try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Error 'ActiveDirectory module is not available. Run this on a domain-joined machine with RSAT or AD PowerShell installed.'
    return
}

$expiredUsers = Search-ADAccount -AccountExpired -UsersOnly |
    Select-Object Name, SamAccountName, UserPrincipalName, Enabled, AccountExpirationDate, PasswordExpired, DistinguishedName

if (-not $IncludeDisabled) {
    $expiredUsers = $expiredUsers | Where-Object { $_.Enabled -eq $true }
}

if ($expiredUsers.Count -eq 0) {
    Write-Host 'No expired user accounts were found.'
    return
}

$expiredUsers | Format-Table -AutoSize

if ($ExportCsv) {
    try {
        $expiredUsers | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported expired accounts to: $CsvPath"
    } catch {
        Write-Error "Failed to export CSV: $($_.Exception.Message)"
    }
}
