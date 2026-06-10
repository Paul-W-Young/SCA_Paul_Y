param(
    [Parameter(Mandatory=$false)]
    [string]$SearchText = '*',

    [Parameter(Mandatory=$false)]
    [switch]$Unlock
)

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "Searching for locked AD accounts matching: $SearchText"

$lockedUsers = Search-ADAccount -LockedOut -Users |
    Where-Object {
        $_.SamAccountName -like $SearchText -or
        $_.Name -like $SearchText -or
        $_.DisplayName -like $SearchText
    }

if (-not $lockedUsers) {
    Write-Host "No locked accounts found."
    exit 0
}

$lockedUsers | Select-Object SamAccountName, Name, DisplayName | Format-Table -AutoSize

if ($Unlock) {
    foreach ($user in $lockedUsers) {
        Write-Host "Unlocking $($user.SamAccountName)..."
        Unlock-ADAccount -Identity $user -ErrorAction Stop
    }
    Write-Host "Unlocked $($lockedUsers.Count) account(s)."
} else {
    Write-Host "Run the script again with -Unlock to unlock the listed accounts."
}