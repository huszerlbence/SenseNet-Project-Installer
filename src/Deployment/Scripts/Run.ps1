[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$false)]
[string]$Mode,
[Parameter(Mandatory=$false)] 
[string]$Settings = "local",
[Parameter(Mandatory=$false)] 
[string]$Params,
[Parameter(Mandatory=$false)] 
[string]$ExportFilter,
[Parameter(Mandatory=$false)] 
[string]$ShowOutput = $True,
[Parameter(Mandatory=$false)] 
[string]$OutputMode = "Host"
)

$ErrorActionPreference = "Stop"
$Result = 0

# ================================================
# ============== GLOBAL VARIABLES ================
# ================================================

$Global:ScriptBaseFolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Global:ProjectSettingsPath = $null
$Global:DefaultSettingsPath = $null
$Global:ProjectSettings = $null
$Global:DefaultSettings = $null
$Global:OutputMode = $OutputMode
$Global:ShowOutput = $ShowOutput

$Global:GlobalSettings = $null
$Global:JsonResult=$Null

$AutoLoadExtensions = [IO.Path]::GetFullPath([IO.Path]::Combine($ScriptBaseFolderPath, "AutoExt"))

# ================================================
# ================ MAIN SCRIPT ===================
# ================================================

# Load steps and functions for plot manager
$AutoLoadExtensionFiles = Get-ChildItem "$AutoLoadExtensions\*.ps1"
foreach ($file in $AutoLoadExtensionFiles) {
	. "$file"
}

 if (Is-Administrator) {
	# Load default settings
	$defaultsettingspath = set-settingspath -settingname "default"
	Write-Log "default setting path: $defaultsettingspath"
	$DefaultSettings = load-settings -settingspath $defaultsettingspath

	# Load Project settings
	$projectsettingspath = set-settingspath $settings
	Write-Log "project setting path: $projectsettingspath"
	$ProjectSettings = load-settings -settingspath $projectsettingspath

	# Extend project settings with default
	$GlobalSettings = Merge-Settings -prior $ProjectSettings -fallback $DefaultSettings
	
	# Add steps section to settings
	$GlobalSettings = Steps-Settings -setting $GlobalSettings
	
	# Run given process
	Run-Modules "$Mode"  

	$Global:JsonResult=$JsonResult
} else {
	Write-Verbose you have to run this script in administrator mode!
}

exit $Result