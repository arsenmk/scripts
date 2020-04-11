# This script takes a source directory as input, where all the image and video
# files are located (note, subdirectories not yet supported), and copies them to
# the specified destination folder under subdirectories named 'yyyy-MM-dd' by default,
# or using using the provided date format, where y, M, d are the format specifiers
# for the year, the month, and the day (respectively) from the image's date taken,
# or if date taken is not set, the last modified time.

# Good to have features for the future:
# - Error handling
# - Support images/videos under subdirectories in the source dirName
# - Support copying images/videos made within date range

# Example usage:
# .\copy_pics.ps1 -sourcePath 'C:\tp2\phone\Camera' -destRoot C:\Arsen\ph3 -folderNameFormat 'yy -- mmm --  -- ddd'
# This will put images taken on April 11, 2020 in a subfolder named '20 -- Apr --  --  Sat'
#
# .\copy_pics.ps1 -sourcePath 'C:\tp2\phone\Camera' -destRoot C:\Arsen\ph3 -folderNameFormat 'YYYY MM dd'
# This will put images taken on April 11, 2020 in a subfolder named '2020 04 11'

param([Parameter(Mandatory=$true)] $sourcePath, [Parameter(Mandatory=$true)] $destRoot, $folderNameFormat="yyyy-MM-dd")
$folderNameFormat = $folderNameFormat.Replace('Y', 'y').Replace('D', 'd').Replace('m', 'M');

function getFolderNameFromDateAndFormat($dt, $format)
{
    return $dt.ToString($format);
}

function getDateFromUnformattedDateTaken($ufdt)
{
    $dateTerms = ($ufdt.trim() -split ' ')[0] -split '/'
    $month = $dateTerms[0].substring(1)
    if ($month.length -eq 1) { $month = "0$month" }
    $day = $dateTerms[1].substring(1)
    if ($day.length -eq 1) { $day = "0$day" }
    $year = $dateTerms[2].substring(1)

    return Get-Date -Year $year -Month $month -Day $day
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
    
    $dateTaken = $null
    if ($unformattedDateTaken) {
        $dateTaken = getDateFromUnformattedDateTaken $unformattedDateTaken
    } else {
        Write-Host "Date taken not available, using Last modified date instead"
        $dateTaken = $f.LastWriteTime
    }

    $folderName = getFolderNameFromDateAndFormat $dateTaken $folderNameFormat
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

