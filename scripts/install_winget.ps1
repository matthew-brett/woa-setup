# From https://github.com/HotCakeX/Harden-Windows-Security/blob/42591df9b2758fa84d817a0e99fae7c6bcd9bdbc/Wiki%20posts/AppControl%20Manager/AppControl%20Manager.md?plain=1#L34
# Retrieve the latest Winget release information
$WingetReleases = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases'
$LatestRelease = $WingetReleases | Select-Object -First 1
# Direct links to the latest Winget release assets
[string]$WingetURL = $LatestRelease.assets.browser_download_url | Where-Object -FilterScript { $_.EndsWith('.msixbundle') } | Select-Object -First 1
[string]$WingetLicense = $LatestRelease.assets.browser_download_url | Where-Object -FilterScript { $_.EndsWith('License1.xml') } | Select-Object -First 1
[string]$LatestWingetReleaseDependenciesZipURL = $LatestRelease.assets.browser_download_url | Where-Object -FilterScript { $_.EndsWith('DesktopAppInstaller_Dependencies.zip') } | Select-Object -First 1
[hashtable]$Downloads = @{
# 'Winget.msixbundle'                 = 'https://aka.ms/getwinget' This is updated slower than the GitHub release
'DesktopAppInstaller_Dependencies.zip' = $LatestWingetReleaseDependenciesZipURL
'Winget.msixbundle'                    = $WingetURL
'License1.xml'                         = $WingetLicense
}
$Downloads.GetEnumerator() | ForEach-Object {
Invoke-RestMethod -Uri $_.Value -OutFile $_.Key
}
Expand-Archive -Path 'DesktopAppInstaller_Dependencies.zip' -DestinationPath .\ -Force
# Get the paths to all of the dependencies
[string[]]$DependencyPaths = (Get-ChildItem -Path .\arm64 -Filter '*.appx' -File -Force).FullName
Add-AppxProvisionedPackage -Online -PackagePath 'Winget.msixbundle' -DependencyPackagePath $DependencyPaths -LicensePath 'License1.xml'

Add-AppPackage -Path 'Winget.msixbundle' -DependencyPath "$($DependencyPaths[0])", "$($DependencyPaths[1])" -ForceTargetApplicationShutdown -ForceUpdateFromAnyVersion
