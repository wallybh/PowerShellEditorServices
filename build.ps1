#!/usr/bin/env pwsh
param(
    [Parameter()]
    [switch]
    $Clean,

    [Parameter()]
    [switch]
    $BootstrapBuildEnv
)

$NeededTools = @{
    OpenSsl = "openssl for macOS"
    DotNet451TargetingPack = ".NET 4.5.1 Targeting Pack"
    PowerShellGet = "PowerShellGet latest"
    InvokeBuild = "InvokeBuild latest"
}

if ((-not $PSVersionTable["OS"]) -or $PSVersionTable["OS"].Contains("Windows")) {
    $OS = "Windows"
} elseif ($PSVersionTable["OS"].Contains("Darwin")) {
    $OS = "macOS"
} else {
    $OS = "Linux"
}


function needsOpenSsl () {
    if ($OS -eq "macOS") {
        try {
            $opensslVersion = (openssl version)
        } catch {
            return $true
        }
    }
    return $false
}

function needsDotNet451TargetingPack () {
    if($BootstrapBuildEnv -and ($OS -eq "Windows")) {
        $hasNet451TargetingPack = Get-CimInstance Win32_Product | Where-Object Name -match '\.NET Framework 4\.5\.1 Multi-Targeting Pack'
        if(-not $hasNet451TargetingPack) {
            return $true
        }
    } elseif($OS -eq "Windows") {
        Write-Host "[Bootstrap] Did not check if the .NET 4.5.1 Targeting Pack is present. To check, run 'build.ps1 -BootstrapBuildEnv'"
    }
    return $false
}

function needsPowerShellGet () {
    if (Get-Module -ListAvailable -Name PowerShellGet) {
        return $false
    }
    return $true
}

function needsInvokeBuild () {
    if (Get-Module -ListAvailable -Name InvokeBuild) {
        return $false
    }
    return $true
}

function getMissingTools () {
    $missingTools = @()

    if (needsOpenSsl) {
        $missingTools += $NeededTools.OpenSsl
    }
    if (needsDotNet451TargetingPack) {
        $missingTools += $NeededTools.DotNet451TargetingPack
    }
    if (needsPowerShellGet) {
        $missingTools += $NeededTools.PowerShellGet
    }
    if (needsInvokeBuild) {
        $missingTools += $NeededTools.InvokeBuild
    }

    return $missingTools
}

function hasMissingTools () {
    return ((getMissingTools).Count -gt 0)
}

if ($BootstrapBuildEnv) {
    $string = "Here is what your environment is missing:`n"
    $missingTools = getMissingTools
    if (($missingTools).Count -eq 0) {
        $string += "* nothing!`n`n Run this script without a flag to build or a -Clean to clean."
    } else {
        $missingTools | ForEach-Object {$string += "* $_`n"}
        $string += "`nAll instructions for installing these tools can be found on PowerShell Editor Services' Github:`n" `
            + "https://github.com/powershell/PowerShellEditorServices#development"
    }
    Write-Host "`n$string`n"
} elseif ($Clean) {
    if(hasMissingTools) {
        Write-Host "You are missing needed tools. Run './build.ps1 -BootstrapBuildEnv' to see what they are."
    } else {
        Invoke-Build Clean
    }
} else {
    if(hasMissingTools) {
        Write-Host "You are missing needed tools. Run './build.ps1 -BootstrapBuildEnv' to see what they are."
    } else {
        Invoke-Build Build
    }
}