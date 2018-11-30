# Prompts for user input
$PackageName=Read-Host -Prompt 'Package Name' # Choco package name which we are creating
$PackageVersion = Read-Host -Prompt 'Version' # Choco package version
$BinaryPath = Read-Host -Prompt 'Exact Path for binary' # Stores path for binary
$BinaryFileName = Read-Host -Prompt 'Binary File Name including extension' #Binary file name to be used with choco package
$BinaryExtensionCheck = $BinaryFileName.Split(".")
if($BinaryExtensionCheck -eq "exe" -or $BinaryExtensionCheck -eq "msi" -or $BinaryExtensionCheck -eq "msu") # validation check for binary type
{
#$installerExtension = Read-Host -Prompt 'Enter Installer type example: Exe or msi'
$SilentArguments = Read-Host -Prompt 'enter silent arguments'
$AuthorName = Read-Host -Prompt 'Enter Author Name'
choco new $PackageName
$installScriptfile = '.\'+$PackageName+'\tools\chocolateyinstall.ps1'
$xmlFile = '.\'+$PackageName+'\'+$PackageName+'.nuspec'
$binaryFile = '.\'+$PackageName+'\tools\'+$BinaryFileName
Write-Output $PackageName
Write-Output $PackageVersion
Write-Output $BinaryPath
Write-Output $BinaryFileName
Write-Output $installScriptfile
Write-Output $xmlFile

robocopy /E $BinaryPath .\$PackageName\tools\
$binarHash = Get-FileHash $binaryFile
Write-Output $binarHash.Hash
$binaryFileHashValue = Write-Output $binarHash.Hash
# Writing Contents to nuspec file
$nuspecFile = @"
<?xml version=`"1.0`" encoding=`"utf-8`"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>{0}</id>
    <title>{0} (Install)</title>
    <version>{1}</version>
    <authors>{2}</authors>
    <owners>BNY Mellon</owners>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <description>Installation of package {0}</description>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
"@ -f $PackageName, $PackageVersion, $AuthorName

# Writing contents to Chocolatey Script

$installPSfileString= @"
`$ErrorActionPreference = 'Stop';

`$packageName= '$PackageName'
`$toolsDir   = `$(Split-Path -parent `$MyInvocation.MyCommand.Definition)
`$fileLocation = Join-Path `$toolsDir '$BinaryFileName'

`$packageArgs = `@{
  packageName   = `$packageName
  fileType      = '$BinaryExtensionCheck[1].ToUpper()'
  file         =  `$fileLocation
  checksum      = '$BinaryFileHashValue'
  checksumType  = 'sha256' 
  silentArgs    = "$SilentArguments"
  validExitCodes= `@(0)
}

Install-ChocolateyPackage `@packageArgs
"@

Write-Output $nuspecFile
Write-Output $installPSfileString

$nuspecFile | out-file -filepath $xmlFile
$installPSfileString | out-file -filepath $installScriptfile

choco pack $xmlFile
}
else
{
Write-Output "Invalid File Extension! Check Binary"
Write-Output "Acceptable Extensions: exe or msi or msu"
}
