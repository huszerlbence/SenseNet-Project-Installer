# Global Functions
Function Set-SettingsPath {
	Param(
            [Parameter(Mandatory=$False)]
            [String]$SettingName = "local"
         )
	$SettingsPath = Get-FullPath ".\Settings\project-$SettingName.json"
	return $SettingsPath
}

Function Load-Settings {
	Param(
            [Parameter(Mandatory=$False)]
            [String]$SettingsPath
         )
	
	$JsonConfig = (Get-Content $SettingsPath) -join "`n" | ConvertFrom-Json 
	return $JsonConfig
}


Function Get-FullPath {
	Param(
		[Parameter(Mandatory=$True)]
        [String]$Path,
		[Parameter(Mandatory=$False)]
        [String]$SubFolder
		)
	if ($Path -like "*:\*") {
		$FullPath = "$Path"
	} else {
		$CombinedPath = [IO.Path]::Combine($ScriptBaseFolderPath, "$Path")
		$FullPath = [IO.Path]::GetFullPath($CombinedPath)
	}	
	return $FullPath
}

Function Run-Modules {
	Param(
		[Parameter(Mandatory=$True)]
        [String]$Mode
		)
	$Output = if ($show) {'Out-Default'} else {'Out-Null'}
	$ProcessSteps = $GlobalSettings.modes."$Mode".Length
	$Step = 0
	if (!($GlobalSettings.modes."$Mode" -eq $Null)) {
		foreach ($ModuleNameSt in $GlobalSettings.modes."$Mode") {
			# Temporary solution for set setting section
			$ModuleNameArr = $ModuleNameSt.Split(":")
			$ModuleName = $ModuleNameArr[0]
			$Section = "Project"
			if (-not ($ModuleNameArr[1] -eq $Null)){
				$Section = $ModuleNameArr[1]
			}
			# end
		
			$script:Result = 0
			$Step += 1
			$Synopsis = Get-Help Module-"$ModuleName" |  foreach { $_.Synopsis  }
			$Progress=(($Step/($ProcessSteps))*100)
			
			Write-Log "================================================" -foregroundcolor "green"
			Write-Log "============= $Mode/$ModuleName =============" -foregroundcolor "green"
			Write-Log "================================================" -foregroundcolor "green"
			Write-Log "Synopsis: $Synopsis" -foregroundcolor "green"			
			Write-Log "Progress: $Progress/100" -foregroundcolor "green"
			
			# write-progress -id 1 -activity "$Mode" -status "$Synopsis" -percentComplete (($Step/($ProcessSteps))*100);
			
			try {
				# Invoke-Expression "Module-$ModuleName" 
				& "Module-$ModuleName" -Section "$Section"
			}
			catch {
				$script:Result = 1
				Write-Log "Error: $_.Message" -foregroundcolor "red"
				$error.clear()
			}
			Write-Log "Exit code: $Result" -foregroundcolor "green"
			Write-Verbose "Exit code: $Result" 
			Write-Log 
		}
		Write-Log 
		Write-Log "--------------------------------------------------"
		Write-Log "-------------------- FINISH ----------------------"
		Write-Log "--------------------------------------------------"
	} else {
		$Synopsis = Get-Help Module-"$Mode" |  foreach { $_.Synopsis  }
		Write-Log "================================================" -foregroundcolor "green"
		Write-Log "============= $Mode/$Mode =============" -foregroundcolor "green"
		Write-Log "================================================" -foregroundcolor "green"
		Write-Log "Synopsis: $Synopsis" -foregroundcolor "green"			
		Write-Log "Progress: 100/100" -foregroundcolor "green"
		
		try {
			Invoke-Expression "Module-$Mode" 
		}
		catch {
			$script:Result = 1
			Write-Log "Error: $_.Message" -foregroundcolor "red"
			$error.clear()
		}
		Write-Log "Exit code: $Result" -foregroundcolor "green"
		Write-Verbose "Exit code: $Result" 
		Write-Log 
	}
}

Function Is-Administrator {
	$Result = $False
	If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
		[Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		$Result = $False
	} else {
		$Result = $True
	}
	return $Result
}

Function Write-Log {
     Param(
		[Parameter(Mandatory=$False)]
        [String]$Message,
		[Parameter(Mandatory=$False)]
        [String]$Mode=$OutputMode,
		[Parameter(Mandatory=$False)]
        [String]$ForegroundColor=(get-host).ui.rawui.ForegroundColor	
		)
		
	if ($ShowOutput -eq $True){
		switch ($Mode) 
		{ 
			"Output" {
				Write-Output $Message
			}
			"Verbose" {
				Write-Verbose $Message
			}
			default {
				Write-Host $Message -ForegroundColor $ForegroundColor
			}
		}
	}
}

Function List-Packages {
	[System.Collections.ArrayList]$Result = @()
	$PackagesPath = Get-FullPath $GlobalSettings.Packages.PackagesPath	
	$Packages = Get-ChildItem "$PackagesPath"
	foreach ($pckg in $Packages) {
		$Result.Add($pckg)
	}	
	return $Result
}

function Set-ConnectionString {
	Param(
            [Parameter(Mandatory=$True)]
            [String]$ConfigPath,
			[Parameter(Mandatory=$True)]
            [String]$ConnectionString
         )
	
	Write-Log "Config path: $ConfigPath"
	Set-ItemProperty $ConfigPath -name IsReadOnly -value $false
	$doc = [xml](get-content $ConfigPath)
	$root = $doc.get_DocumentElement();
	$root.connectionStrings.add.ConnectionString = $ConnectionString
	$doc.Save($ConfigPath)
}

function Set-AppSetting {
	Param(
            [Parameter(Mandatory=$True)]
            [String]$ConfigPath,
			[Parameter(Mandatory=$True)]
            [String]$Key,
			[Parameter(Mandatory=$True)]
            [String]$Value
         )
	
	Write-Log "Config path: $ConfigPath"
	Set-ItemProperty $ConfigPath -name IsReadOnly -value $false
	$doc = [xml](get-content $ConfigPath)
	#$root = $doc.get_DocumentElement();
	# $obj = $root.configuration.appSettings.add | where {$_.Key -eq $Key}
	$obj = $doc.configuration.appSettings.add | where {$_.Key -eq $Key}
	if ($obj) {
		$obj.value = $Value
	} else {
		$newAppSetting = $doc.CreateElement("add")
		$doc.configuration.appSettings.AppendChild($newAppSetting)
		$newAppSetting.SetAttribute("key",$Key);
		$newAppSetting.SetAttribute("value",$Value);	
	}
	$doc.Save($ConfigPath)
}

# Help Set-ConnectionString

# $connectionString = 'Persist Security Info=False;Initial Catalog=masik;Data Source=.\SQL2016;Integrated Security=true'
# $importConfig = 'C:\Development\LeisureJoe\InstallTest\Deployment\Scripts\Import.exe.config'
# Set-ConnectionString -ConfigPath $importConfig -ConnectionString $connectionString

function Set-PathTooLongHandling {
	Param(
            [Parameter(Mandatory=$True)]
            [String]$ConfigPath
         )

	#  <AppContextSwitchOverrides value="Switch.System.IO.UseLegacyPathHandling=false;Switch.System.IO.BlockLongPaths=false" />		 
	
	Write-Log "Config path: $ConfigPath"
	Set-ItemProperty $ConfigPath -name IsReadOnly -value $false
	$doc = [xml](get-content $ConfigPath)
	if (!($doc.configuration.runtime.AppContextSwitchOverrides)){
		$override = $doc.CreateElement("AppContextSwitchOverrides")
		$override.SetAttribute("value","Switch.System.IO.UseLegacyPathHandling=false;Switch.System.IO.BlockLongPaths=false");
		$doc.configuration.runtime.AppendChild($override)		
	}
	$doc.Save($ConfigPath)
}

# function Set-UrlList {
	# Param(
            # [Parameter(Mandatory=$True)]
            # [String]$ConfigPath,
			# [Parameter(Mandatory=$True)]
            # [String]$Host
         # )
	# # <urlList>
      # # <sites>
        # # <site path="/Root/Sites/Default_Site">
          # # <urls>
            # # <url host="localhost" auth="Forms" />
          # # </urls>
        # # </site>
      # # </sites>
    # # </urlList>
		 
	# Write-Log Config path: $ConfigPath
	# $doc = [xml](get-content $ConfigPath)
	# if (!($doc.configuration.sensenet.urlList)){
		# $override = $doc.CreateElement("urlList")
		# $override = $doc.CreateElement("sites")
		# $override.SetAttribute("value","Switch.System.IO.UseLegacyPathHandling=false;Switch.System.IO.BlockLongPaths=false");
		# $doc.configuration.runtime.AppendChild($override)		
	# }
	# $doc.Save($ConfigPath)
# }

# Functions uncertain if needed
Function Go-Verbose {
     [CmdletBinding()]Param()
     Write-Log -Message "Alright, you prefer talkative functions. First of all, I appreciate your wish to learn more about the common parameter -Verbose. Secondly, blah blah.." -Mode Verbose 
     Write-Log "This is self-explanatory, anyway."
}

Function Register-PSRepositoryFix {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [String]
        $Name,

        [Parameter(Mandatory=$true)]
        [Uri]
        $SourceLocation,

        [ValidateSet('Trusted', 'Untrusted')]
        $InstallationPolicy = 'Trusted'
    )

    $ErrorActionPreference = 'Stop'

    Try {
        Write-Log -Message 'Trying to register via ​Register-PSRepository' -Mode Verbose 
        ​Register-PSRepository -Name $Name -SourceLocation $SourceLocation -InstallationPolicy $InstallationPolicy
        Write-Log -Message 'Registered via Register-PSRepository' -Mode Verbose 
    } Catch {
        Write-Log -Message 'Register-PSRepository failed, registering via workaround' -Mode Verbose 

        # Adding PSRepository directly to file
        Register-PSRepository -name $Name -SourceLocation $env:TEMP -InstallationPolicy $InstallationPolicy
        $PSRepositoriesXmlPath = "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\PowerShellGet\PSRepositories.xml"
        $repos = Import-Clixml -Path $PSRepositoriesXmlPath
        $repos[$Name].SourceLocation = $SourceLocation.AbsoluteUri
        $repos[$Name].PublishLocation = (New-Object -TypeName Uri -ArgumentList $SourceLocation, 'package/').AbsoluteUri
        $repos[$Name].ScriptSourceLocation = ''
        $repos[$Name].ScriptPublishLocation = ''
        $repos | Export-Clixml -Path $PSRepositoriesXmlPath

        # Reloading PSRepository list
        Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
        Write-Log -Message 'Registered via workaround' -Mode Verbose 
    }
}

# Creates a new directory using the specified path.
function New-Directory([string]$dir) {
    New-Item $dir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

}


# The intent of this script is to locate and return the path to the MSBuild directory that
# we should use for bulid operations. The preference order for MSBuild to use is as 
# follows
#
#   1. MSBuild from an active VS command prompt
#   2. MSBuild from a machine wide VS install
#   3. MSBuild from the xcopy toolset 
#
# This function will return two values: the kind of MSBuild chosen and the MSBuild directory.
function Get-MSBuildKindAndDir([switch]$xcopy = $false) {
    if ($xcopy) { 
        Write-Log "xcopy"
        Write-Log "(Get-MSBuildDirXCopy)"
        return
    }
    # MSBuild from an active VS command prompt.  
    if (${env:VSINSTALLDIR} -ne $null) {
        # This line deliberately avoids using -ErrorAction.  Inside a VS command prompt
        # an MSBuild command should always be available.
        $command = (Get-Command msbuild -ErrorAction SilentlyContinue)
        if ($command -ne $null) {
            $p = Split-Path -parent $command.Path
            Write-Log "vscmd"
            Write-Log "$p"
            return
        }
    }
    # Look for a valid VS installation
    try {
        $p = Get-VisualStudioDir
        $p = Join-Path $p "MSBuild\15.0\Bin"
        Write-Log "vsinstall"
        Write-Log "$p"
        return
    }
    catch { 
        # Failures are expected here when no VS installation is present on the machine.
    }
    Write-Log "xcopy"
    Write-Log "(Get-MSBuildDirXCopy)"
    return
}

# Locate the xcopy version of MSBuild.
function Get-MSBuildDirXCopy() {
    $version = "0.1.2"
    $name = "RoslynTools.MSBuild"
    $p = Get-BasicTool $name $version
    $p = Join-Path $p "tools\msbuild"
    return $p
}

# Get the MSBuild directory.
function Get-MSBuildDir([switch]$xcopy = $false) {
    $both = Get-MSBuildKindAndDir -xcopy:$xcopy
    return $both[1]
}

# Get the directory of the first Visual Studio which meets our minimal requirements.
function Get-VisualStudioDir() {
    $vswhere = Join-Path (Get-BasicTool "vswhere" "1.0.50") "tools\vswhere.exe"
    $output = & $vswhere -requires Microsoft.Component.MSBuild -format json | Out-String
    if (-not $?) {
        throw "Could not locate a valid Visual Studio"
    }
    $j = ConvertFrom-Json $output
    $p = $j[0].installationPath
    return $p
}

# Ensure that MSBuild is installed and return the path to the executable to use.
function Get-MSBuild([switch]$xcopy = $false) {
    $both = Get-MSBuildKindAndDir -xcopy:$xcopy
    $msbuildDir = $both[1]
    switch ($both[0]) {
        "xcopy" { break; }
        "vscmd" { break; }
        "vsinstall" { break; }
        default {
            throw "Unknown MSBuild installation type $($both[0])"
        }
    }
    $p = Join-Path $msbuildDir "msbuild.exe"
    return $p
}

# if ($subproperty.Value.GetType().FullName -eq "System.Object[]") 

# Merge two json object
Function Merge-Settings {
	Param(
		[Parameter(Mandatory=$True)]
        [Object]$prior,
		[Parameter(Mandatory=$True)]
        [Object]$fallback
		)
	
	foreach ($property in $fallback.psobject.Properties) {
		if ($prior.PSObject.Properties.Match($property.Name).Count) {
				# should be use with settings instead of hardcoded
				$mergePropName = "Modes"   
				# if prop exists and mergePropName we merge subproperties 
				if ($property.Name -eq $mergePropName) {
					$subobj = $prior."$mergePropName"
					foreach ($subproperty in $property.Value.psobject.Properties) {
						if (-Not $subobj.PSObject.Properties.Match($subproperty.Name).Count) {
							$prior.Modes | Add-Member -MemberType NoteProperty -Name $subproperty.Name -Value $subproperty.Value
						}
					}
				}
		} else {
				$prior | Add-Member -MemberType NoteProperty -Name $property.Name -Value $property.Value
		}
	}
	
	return $prior
}

Function Steps-Settings {
	Param(
		[Parameter(Mandatory=$True)]
        [Object]$setting
		)
	$steps = (Get-ChildItem function:\Module-*).Name.Substring(7)
	$setting | Add-Member -MemberType NoteProperty -Name Steps -Value $steps
	return $setting
}