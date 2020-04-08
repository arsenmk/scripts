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

