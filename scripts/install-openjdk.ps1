Param(
    [string] $Version = '17.0.8.1',
    [string] $FolderVersion = '17.0.8.1+1',
    [string] $InstallDestination = $null
)

$ErrorActionPreference = 'Stop'

if ("$env:JAVA_HOME_17_X64" -and (Test-Path (Join-Path "$env:JAVA_HOME_17_X64" "bin"))) {
    Write-Host "Java is already installed to '$env:JAVA_HOME_17_X64'..."
    $java_home = $env:JAVA_HOME_17_X64
} else {
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $HOME_DIR = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }

    if ($IsMacOS) {
        $ext = "tar.gz"
        $url = "https://aka.ms/download-jdk/microsoft-jdk-$Version-macOS-x64.tar.gz"
    } elseif ($IsLinux) {
        $ext = "tar.gz"
        $url = "https://aka.ms/download-jdk/microsoft-jdk-$Version-linux-x64.tar.gz"
    } else {
        $ext = "zip"
        $url = "https://aka.ms/download-jdk/microsoft-jdk-$Version-windows-x64.zip"
    }

    $jdk = Join-Path "$HOME_DIR" "openjdk"
    if ($InstallDestination) {
        $jdk = $InstallDestination
    }
    Write-Host "Install destination is '$jdk'..."

    $jdkTemp = Join-Path "$HOME_DIR" "openjdk-temp"
    $archive = Join-Path "$jdkTemp" "openjdk.$ext"

    # download
    Write-Host "Downloading OpenJDK to '$archive'..."
    New-Item -ItemType Directory -Force -Path "$jdkTemp" | Out-Null
    (New-Object System.Net.WebClient).DownloadFile("$url", "$archive")

    # install
    Write-Host "Extracting OpenJDK to '$jdk'..."
    New-Item -ItemType Directory -Force -Path "$jdk" | Out-Null
    if ($IsMacOS -or $IsLinux) {
        tar -vxzf "$archive" -C "$jdk"
    } else {
        [System.IO.Compression.ZipFile]::ExtractToDirectory("$archive", "$jdk")
    }

    # set the JAVA_HOME
    if ($IsMacOS) {
        $java_home = Join-Path "$jdk" "jdk-$FolderVersion/Contents/Home"
    } else {
        $java_home = Join-Path "$jdk" "jdk-$FolderVersion"
    }
}

Write-Host "##vso[task.setvariable variable=JAVA_HOME;]$java_home"
$env:JAVA_HOME = "$java_home"

# make sure that JAVA_HOME/bin is in the PATH
$javaBin = Join-Path "$java_home" "bin"
if (-not $env:PATH.Contains($javaBin)) {
    $env:PATH = "$javaBin" + [IO.Path]::PathSeparator + "$env:PATH"
    Write-Host "##vso[task.setvariable variable=PATH;]$env:PATH"
}

java -version

exit $LASTEXITCODE
