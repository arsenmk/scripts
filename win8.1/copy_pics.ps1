# This script takes a source directory as input, where all the image and video
# files are located (note, subdirectories not yet supported), and copies them to
# the specified destination folder under subdirectories named 'YYYY-MM-DD', where
# YYYY, MM, DD are the year, month and the day from the image's date taken, or if
# date taken is not set, the last modified time.

# For the initial version no proper error handling is added.
# Good to have features for the future:
# - Error handling
# - Support images/videos under subdirectories in the source dirName
# - Support copying images/videos made within date range
# - Support folder name template argument

param([Parameter(Mandatory=$true)] $sourcePath, [Parameter(Mandatory=$true)] $destRoot, $folderNameFormat="yyyy-mm-dd")

function getFolderNameFromUnformattedDateTaken($ufdt)
{
    $dateTerms = ($ufdt.trim() -split ' ')[0] -split '/'
    $month = $dateTerms[0].substring(1)
	if ($month.length -eq 1) { $month = "0$month" }
    $day = $dateTerms[1].substring(1)
	if ($day.length -eq 1) { $day = "0$day" }
    $year = $dateTerms[2].substring(1)

    return "$year-$month-$day"
}

function getFolderNameFromLastWriteTime($lwt)
{
	$month = $lwt.Month;
	if ($month.length -eq 1) { $month = "0$month" }
	$day = $lwt.Day;
	if ($day.length -eq 1) { $day = "0$day" }
	$year = $lwt.Year;
	
	return "$year-$month-$day"
}

$files = Get-ChildItem -Path "$sourcePath\\*" -Include ('*.jpg', '*.mp4')

if ($files.length -eq 0) {
	Write-Host "No files found, exiting"
	exit;
}

$shellObject = New-Object -ComObject Shell.Application
$dirName = $files[0].Directory.FullName
$dirObject = $shellObject.NameSpace($dirName)

$propIndex = -1;

foreach ($f in $files) {
	$fileObject = $dirObject.ParseName($f.Name)

	if ($propIndex -eq -1) {
	    $property = 'Date taken'
	    for (; $dirObject.GetDetailsOf($dirObject.Items, $propIndex) -ne $property; ++$propIndex) { }  
	}

	$unformattedDateTaken = $dirObject.GetDetailsOf($fileObject, $propIndex)
    $folderName = ''
	if (!$unformattedDateTaken) {
	    Write-Host "Date taken not available, using Last modified date instead"
	    $folderName = getFolderNameFromLastWriteTime $f.LastWriteTime
	} else {
	    $folderName = getFolderNameFromUnformattedDateTaken $unformattedDateTaken
	}

	Write-Host "${f.Name} : $folderName"
	
	$destPath = Join-Path -Path $destRoot -ChildPath $folderName
	if (!(Test-Path -Path $destPath)) {
	    Write-Host "Creating directory $destPath"
		New-Item -ItemType directory -Path $destPath
	} else {
		Write-Host "Directory $destPath already exists"
	}

	Copy-Item -Path $f.FullName -Destination $destPath
}

