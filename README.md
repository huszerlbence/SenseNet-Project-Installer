# SenseNet Project Installer

## How it works

This is basically a package of various powershell scripts used by my team creating and managing custom project installations. It's uses predefined vs solution with SN7 packages at the moment and contains sn-webpages for easy to understand sensenet handling, but official channels promote to avoid sn-webpages package and use only sn-services with custom client-side solution based (e.g. React). For fine tuning or to create custom solution for the installer see sensenet official channels (e.g.  https://community.sensenet.com/docs/install-sn-from-nuget/)
We aim for an easy to use gui alongside with the scripts too eventually, but it can basically run manually from ps window for now. 

It contains the following scripts for now:
- Create, start and stop IIS sites
- Setup host file
- Unzip archives
- Build solutions
- Install Sense/Net site from source package
- Get latest from TFS
- Import/Export content and index populate Sense/Net site
- and some other custom scripts

## Prerequisits

Prerequisits are mostly come from the scripts that are made for managing Sense/Net:

1. Microsoft SQL Server
	a.       SQL Server Configuration Manager
2. Visual Studio
3. IIS
3. PowerShell 
4. Environment settings
	- snadmin sensenet install (at least some steps) needs a solution with predefined nuget packages and webfolder configuration, the installer contains an example under "Source" folder for now 
	- some scripts may use the 7-Zip application, if so download and install it from http://www.7-zip.org/
	- Enable the powershell script running permission: PS C:\PowerShell-PowerUp> Set-ExecutionPolicy unrestricted

## Powershell script files:

- `Start-IISSite`: starts the site by the given parameter. 
```powershell
Start-IISSite.ps1 [SiteName]
```
- `Stop-IISSite`: stops the site by the given parameter.
```powershell
Stop-IISSite.ps1 [SiteName]
```
- Build-Solution: builds the solution by the given parameter.
```powershell
Build-Solution.ps1` -slnPath [Solution file path. It is .sln file]
```
- `Create-IISSite`: creates the application pool and the site. In the first parameter you need to set the application pool (same site name) and in the second parameter you need to set the site’s physical path on the hard drive.
```powershell
Create-IISSite.ps1 -DirectoryPath [site’s physicalPath] -SiteName [SiteName] -PoolName [Application Pool Name] -SiteHosts [string list of urls for bindings]
```
- `GetLatestSolution`: gets the latest version from the repository.
```powershell
GetLatestSolution.ps1 -tfexepath [tf.exe physical path] –location [project source folder path]
```
- `Import-Module`: imports the project files to the repository.
- `Export-Module`: exports the project files from the repository.
- `Index-Project`: runs indexpopulation process.
- `Init-Assemblies`: copies the SenseNet dlls into /bin and /tools folders and edits the config files.
- `init-functions`: initialization helper functions.
- `Set-Host`: set urls in hosts file.
- `Unzip-File`: unzips the zip file (example: SenseNet package) to the destination folder.
```
Unzip-File.ps1 -filename [zip file path] -destname [destination path]
```
- `Run`: We've created predefined `steps` that call the scripts with parameters from projects settings. You can run these different set of steps called `plots`. An example plot is `fullinstall`: 

** fullinstall: runs sensenet install process from creating the database through install custom project to create iis site.

## Local install 

If everything've set right, you can call the scripts simply with the following parameter:
```powershell
Run.ps1 fullinstall
```

which is a short version of

```powershell
Run.ps1 -plot fullinstall -settings local 
```

By deafult installer scripts shows output of tools but not custom comments or informations.
To hide all feedback call the `Run` script with -showoutput $false or to show custom informations use -verbose parameter

```powershell
Run.ps1 -plot fullinstall -settings local -showoutput $true -verbose
```

## Build server example steps

The same scripts that are used locally can be used with visual studio's build server.

1.	Stop the site 
2.	Unzip the SenseNet package
3.	Build the SenseNet solution
4.	Install SenseNet
5.	Copy DLLs to /bin and /tools folder
6.	Get latest version
7.	Build solution
8.	Import contents to repository
9.	Indexpopulation
10.	Start the site 

## Known issues

There are some steps we've not fully automated yet. So some manual setups may required, such as:

- The script won't automatically map your Visual Studio version and its location which is needed to get latest tfs and solution build steps. You have to set `tf.exe` path properly in `project-local.json`'s Tools.VisualStudio property
- Unziping archive script uses 7zip, the location for `7za.exe` file needs to be set in `project-local.json` too
- If you use sql alias like `MySenseNetContentRepositoryDatasource` in default Sense/Net install, you have to set it manually before using the script or you have to set different Datasource in `project-local.json`
