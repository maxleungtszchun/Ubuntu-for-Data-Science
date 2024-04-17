#!/opt/microsoft/powershell/pwsh

Install-Module -Name PSReadLine -Scope CurrentUser -Force
Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
Install-Module -Name z -Scope CurrentUser -Force
Install-Module -Name posh-git -Scope CurrentUser -Force
Install-Module -Name PSfzf -Scope CurrentUser -Force
Install-Module -Name QueryExcel -Scope CurrentUser -Force

$profile_text = @'
oh-my-posh init pwsh --config "~/dracula.omp.json" | Invoke-Expression
Function Edit-Profile { nano $PROFILE.CurrentUserAllHosts }
#region conda initialize
# !! Contents within this block are managed by 'conda init' !!
If (Test-Path "~/miniforge3/bin/conda") {
    (& "~/miniforge3/bin/conda" "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
}
#endregion

if ($host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine
    Import-Module Terminal-Icons
    Import-Module z
    Import-Module posh-git
    Import-Module PSFzf
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
}

function Set-PoshGitStatus {
    $global:GitStatus = Get-GitStatus
    $env:POSH_GIT_STRING = Write-GitStatus -Status $global:GitStatus
}
New-Alias -Name 'Set-PoshContext' -Value 'Set-PoshGitStatus' -Scope Global -Force
$GitPromptSettings.BranchColor.ForegroundColor = '#f8f8f2'
$GitPromptSettings.BeforeStatus = ""
$GitPromptSettings.AfterStatus = ""

'@

Add-Content -Path $Profile.CurrentUserAllHosts -Value $profile_text
Write-Host 'install_pwsh_packages.ps1 is done' -ForegroundColor Green
