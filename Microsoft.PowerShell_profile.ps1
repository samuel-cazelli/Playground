oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\meu.omp.json" | Invoke-Expression


function Write-ColorOutput($ForegroundColor)
{
    # save the current color
    $fc = $host.UI.RawUI.ForegroundColor

    # set the new color
    $host.UI.RawUI.ForegroundColor = $ForegroundColor

    # output
    if ($args) {
        Write-Output $args
    }
    else {
        $input | Write-Output
    }

    # restore the original color
    $host.UI.RawUI.ForegroundColor = $fc
}


function Get-GitSendCurrentBranchTo { 
    
    param
    ($toBranch = 'dev')

    $currentBranch = $(git rev-parse --abbrev-ref HEAD) 
    Write-ColorOutput green ">>>git fetch<<<"
    & git fetch
    Write-ColorOutput green ">>>git branch -D $toBranch<<<"
    & git branch -D $toBranch 
    & Write-ColorOutput green ">>>git checkout $toBranch<<<"
    & git checkout $toBranch 
    & Write-ColorOutput green ">>>git pull $toBranch<<<"
    & git pull 
    & Write-ColorOutput green ">>>git merge $currentBranch into $toBranch<<<"
    & git merge $currentBranch 

    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Push")
        [System.Management.Automation.Host.ChoiceDescription]::new("&Revert")
        [System.Management.Automation.Host.ChoiceDescription]::new("&Do Nothing")        
    )
    $shouldSend = $Host.UI.PromptForChoice($title, 'Should push?', $choices, 2)
    
    if ( $shouldSend -eq '0') {
        Write-ColorOutput green ">>>git push to $toBranch<<<"
        #git push
        Write-ColorOutput green ">>>git checkout $currentBranch<<<"
        git checkout $currentBranch
    } 
    elseif ($shouldSend -eq '1') {
        Write-ColorOutput green ">>>git reset $toBranch<<<"
        git reset --merge
        Write-ColorOutput green ">>>git checkout $currentBranch<<<"
        git checkout $currentBranch
    }
}
New-Alias -Name sendTo -Value Get-GitSendCurrentBranchTo

