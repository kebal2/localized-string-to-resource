$exists = Test-Path "LocalizationKeys"
If (-not $exists) {
    New-Item -ItemType Directory -Path "LocalizationKeys"
}

Get-Childitem -Path . -Include "*.cshtml" -Recurse | ForEach-Object {     
    $file = $_
    $fileContent = Get-Content $file -Encoding UTF8
    $keyFilePath = ($file.Directory | Resolve-Path -Relative).Trim('.');
    $outFileName = $file.Name.TrimEnd('cshtml') + "key";
    $locPath = Join-Path -Path "LocalizationKeys" -ChildPath $keyFilePath
    $locFilePath = Join-Path -Path $locPath -ChildPath $outFileName
    
    If (Test-Path $locFilePath) {
        Remove-Item -Path $locFilePath
    }        
    
    If (-not (Test-Path $locPath)) {
        New-Item -ItemType Directory -Path $locPath
    }
    
    $varName = $fileContent | 
    Select-String '@inject.*IViewLocalizer *(\w*) {0,}$' -AllMatches | 
    Foreach-Object { $_.Matches } | 
    Foreach-Object { $_.Groups[1].Value } 

    $localizerKeyExtractor = '@' + $varName + '\["(.*?)"\]'
    
    $fileContent | Select-String $localizerKeyExtractor -AllMatches | Foreach-Object { $_.Matches } | Foreach-Object { $_.Groups[1].Value | Out-File -FilePath $locFilePath -Append -Encoding utf8 }
}
