<# 
.SYNOPSIS
Creates bulk Active Directory users from a CSV file.

.DESCRIPTION
Requires the ActiveDirectory PowerShell module and a domain-joined machine with sufficient permissions.

.CSV FORMAT
Name,GivenName,Surname,sAMAccountName,UserPrincipalName,DisplayName,Email,Password
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CsvPath,

    [Parameter(Mandatory=$false)]
    [string]$UsersOU = 'OU=IT,DC=Adatum,DC=com',

    [switch]$WhatIf
)

try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Error 'ActiveDirectory module is not available. Run this on a domain-joined system with RSAT or AD PowerShell installed.'
    return
}

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV file not found: $CsvPath"
    return
}

$users = Import-Csv -Path $CsvPath

foreach ($user in $users) {
    $samAccountName = $user.sAMAccountName
    $upn = $user.UserPrincipalName
    $name = $user.Name
    $displayName = $user.DisplayName
    $email = $user.Email
    $password = $user.Password
    $givenName = $user.GivenName
    $surname = $user.Surname

    if (-not $samAccountName -or -not $upn -or -not $password) {
        Write-Warning "Skipping row because required fields are missing: $($user | ConvertTo-Json -Compress)"
        continue
    }

    try {
        $existing = Get-ADUser -Filter { SamAccountName -eq $samAccountName } -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Warning "User already exists: $samAccountName"
            continue
        }

        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force

        New-ADUser `
            -Name $name `
            -GivenName $givenName `
            -Surname $surname `
            -SamAccountName $samAccountName `
            -UserPrincipalName $upn `
            -DisplayName $displayName `
            -EmailAddress $email `
            -Path $UsersOU `
            -AccountPassword $securePassword `
            -Enabled $true `
            -ChangePasswordAtLogon $false `
            -WhatIf:$WhatIf

        if (-not $WhatIf) {
            Write-Host "Created AD user: $name ($samAccountName)"
        } else {
            Write-Host "WhatIf: AD user would be created: $name ($samAccountName)"
        }
    } catch {
        Write-Error ("Failed to create user {0}: {1}" -f $samAccountName, $_.Exception.Message)
    }
}