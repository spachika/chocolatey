################################################################################################
# Name: Choco Packaging Script
# Purpose: To create a choco package with inputs from user
# Author: Santosh Reddy Pachika https:\\github.com\spachika
# Contributer: Vinay Chander Kasim Ramesh https:\\github.com\vinayckr
#
# Required Parameters
# Package Name
# Package Version
# Binary Path
# Share folder path or url if binary size is more than 1 GB
# Silent Arguments
################################################################################################
$PackageName=Read-Host -Prompt 'Package Name' # Choco package name to be created

########### Searches source lists to find out packages related to given package name ###########
$repoSearch = choco search $PackageName 
$packagesFound = $repoSearch | Select-String -Pattern "^[0-9]* packages"
$NofPackages = $packagesFound.ToString().Split(' ');

if($NofPackages[0] -ne 0)
{

foreach ($item in $repoSearch)
{
$props = $item.Split(' ');
Write-Host $props[0]     "|"     $props[1]
}

$userChoice = Read-Host -Prompt 'If you are unable to find the package in the repo, Key in Yes to continue with package creation Else No. Valid Input Yes|No'

}
else
{
$userChoice = 'Yes'

}
###################################################################################################
if($userChoice.ToLower() -like ('yes'))
{
$PackageVersion = ''

#Prompts user to Enter version number and Validates version number format
do{

if($PackageVersion -eq '')
{
$PackageVersion = Read-Host -Prompt 'Enter Version Number'
}
elseif($PackageVersion -notmatch '^(\d+\.)?(\d+\.)?(\*|\d+)$')
{
Write-Host "Enter Valid Version Number, Valid Format number.number.number" -ForegroundColor Red
$PackageVersion = Read-Host -Prompt 'Enter Version Number'
}

}until($PackageVersion -match '^(\d+\.)?(\d+\.)?(\*|\d+)$')

######Calculates Folder size of binary and prompts user to do necessary changes#########

$BinaryPath = Read-Host -Prompt 'Exact Path for binary' # Stores path for binary

$BinariesSize = ("{0:N2} MB" -f ((Get-ChildItem $BinaryPath -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB)).Split(" ")
Write-Output $BinariesSize[0]
if($BinariesSize -ge 10.00)
{
Write-Host "Provided Binaries Size" $BinariesSize[0] "is Greater than 1 GB" -ForegroundColor Red
Write-Host "Place dependencies in a Share path and specify the share path" -ForegroundColor Red
$sharePath = Read-Host -Prompt 'Share path or url for binary'
}
########################################################################################

#######prevents user from giving null values for sharepath##############################
if($sharePath -eq '')
{

do{

Write-Host "Share Path cannot be empty" -ForegroundColor Red
$sharePath = Read-Host -Prompt 'Share path or url for binary'

}until($sharePath -ne '')

}

########################################################################################

#########Prevents user from giving null to binary file##################################

$BinaryFileName = Read-Host -Prompt 'Binary File Name including extension' #Binary file name to be used with choco package

if($BinaryFileName -eq '')
{

do{

Write-Host "Share Path cannot be empty" -ForegroundColor Red

}until(($BinaryFileName = Read-Host -Prompt 'Binary File Name') -ne '')

}
########################################################################################

##########Checks for extension type and creates package#################################
do{
$BinaryExtensionCheck = $BinaryFileName.Split(".")


if($BinaryExtensionCheck -eq "exe" -or $BinaryExtensionCheck -eq "msi" -or $BinaryExtensionCheck -eq "msu") # validation check for binary type
{

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

############# Writing Contents to nuspec file##########################################
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
    <projectSourceUrl>{3}</projectSourceUrl>
  </metadata>
</package>
"@ -f $PackageName, $PackageVersion, $AuthorName, $sharePath
########################################################################################

############### Writing contents to Chocolatey Script###################################

$installPSfileString= @"
`$ErrorActionPreference = 'Stop';

`$packageName= '$PackageName'
`$toolsDir   = `$(Split-Path -parent `$MyInvocation.MyCommand.Definition)
`$fileLocation = Join-Path `$toolsDir '$BinaryFileName'

`$packageArgs = `@{
  packageName   = `$packageName
  fileType      = $BinaryExtensionCheck[1].ToUpper()
  file         =  `$fileLocation
  checksum      = '$BinaryFileHashValue'
  checksumType  = 'sha256' 
  silentArgs    = "$SilentArguments"
  validExitCodes= `@(0)
}

Install-ChocolateyPackage `@packageArgs
"@

########################################################################################

Write-Output $nuspecFile
Write-Output $installPSfileString

#############Creates a nuspec file and chocolateyinstall file ##########################
$nuspecFile | out-file -filepath $xmlFile
$installPSfileString | out-file -filepath $installScriptfile

########################################################################################
choco pack $xmlFile # Creates choco package
}
else
{
Write-Output "Invalid File Extension! Check Binary"
Write-Output "Acceptable Extensions: exe or msi or msu"
}
}until(($BinaryFileName = Read-Host -Prompt 'Give Proper Binary File name').Split(".")[1] -like ('exe'-or'msi'-or'msu'))
########################################################################################
}
else
{
   Write-Host 'Thank You'
}
