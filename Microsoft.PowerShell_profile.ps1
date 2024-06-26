Import-Module posh-git

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\meu.omp.json" | Invoke-Expression

# Navegação com autocomplete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

######################################################################################################

function Get-NewBranch {
    param
    ($branch)

    if ($branch -ne '') {
        git checkout -b $branch
    }
}
New-Alias -Name b -Value Get-NewBranch

######################################################################################################

function Get-Pull {
    git pull
}
New-Alias -Name p -Value Get-Pull

######################################################################################################

function Write-ColorOutput($ForegroundColor) {
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

######################################################################################################

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
        git push
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

######################################################################################################

function Get-GitParentBranch {

    param
    ($currentBranch = '')

    # Get the current branch name
    if ($currentBranch -eq '') {
        $currentBranch = git rev-parse --abbrev-ref HEAD
    }

    # Get the output of git show-branch
    $gitShowBranch = git show-branch $currentBranch

    # Filter lines containing '*'
    $asteriskLines = $gitShowBranch | Select-String '\*'



    # Filter out lines with the current branch name
    $filteredLines = $asteriskLines | Where-Object { $_ -notmatch [regex]::Escape($currentBranch) }

    # Get the first line after filtering
    $firstLine = $filteredLines | Select-Object -First 1

    # Extract the text within square brackets
    $result = [regex]::Match($firstLine, '\[(.*?)\]').Groups[1].Value

    # Remove the caret (^) and tilde (~) characters and everything after them
    $result = $result -replace '\^.*', '' -replace '~.*', ''

    $result # Output the final result

}
New-Alias -Name parentBranch -Value Get-GitParentBranch

######################################################################################################

function Get-GitRenameMergedBranches {

    param
    ($currentBranch = '')

    if ($currentBranch -eq '') {
        $currentBranch = git rev-parse --abbrev-ref HEAD
    }

    $mergedBranches = git branch --merged $currentBranch

    $mergedBranches = $mergedBranches | Select-String  '(fix*)', '(feature*)', '(us*)'

    $mergedBranches = $mergedBranches | ForEach-Object { if ($_ -notmatch '^\s*merge') { $_ } }

    echo $mergedBranches

    echo '----------------------------'

    $mergedBranches | ForEach-Object { 
        $choices = @(
            [System.Management.Automation.Host.ChoiceDescription]::new("&rename")
            [System.Management.Automation.Host.ChoiceDescription]::new("&next")
        )

        Write-Host "$currentBranch -> $_" 
        
        $shouldSend = $Host.UI.PromptForChoice($title, '', $choices, 1)
        
        if ( $shouldSend -eq '0') {
            $newName = 'merged/' + $currentBranch + '/' + $_.ToString().Trim();
            git branch -m $_.ToString().Trim() $newName
        }
    }
}
New-Alias -Name hideold -Value Get-GitRenameMergedBranches

######################################################################################################

function Get-GitDeleteMergedBranches {
    git branch | Select-String -Pattern "merged" | %{ git branch -d $_.ToString().Trim() }
}
New-Alias -Name deleteold -Value Get-GitDeleteMergedBranches

######################################################################################################

function Get-GitCheckoutBranch {
    git checkout $(git branch | ForEach-Object { if ($_ -notmatch '^\s*merge') { $_ } }  | fzf).ToString().Trim()
}
New-Alias -Name c -Value Get-GitCheckoutBranch

######################################################################################################

function Get-GitMergeBranch {
    git merge $(git branch | ForEach-Object { if ($_ -notmatch '^\s*merge') { $_ } }  | fzf).ToString().Trim()
}
New-Alias -Name m -Value Get-GitMergeBranch

######################################################################################################

function Get-SearchFiles {
    if ((Get-Location | select -ExpandProperty Path) -match '(frontend)'){
        Get-ChildItem ./src -Recurse -Name | ForEach-Object { if ($_ -notmatch '(debug)|(bin)') { $_ } } | fzf --exact | ii
    }else{
        Get-ChildItem . -Recurse -Name | ForEach-Object { if ($_ -notmatch '(debug)|(bin)') { $_ } } | fzf --exact | ii
    }
}
New-Alias -Name s -Value Get-SearchFiles
