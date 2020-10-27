param($defaultLang = "hu", $langageCodes = "hu, en, de, fr", $template = ".\blank.resx")

function CollectLocalizationKeys {

    $outputPath = "./Resources"
    $filesCreated = @()

    Get-Childitem -Path . -Include "*.csproj" -Recurse | ForEach-Object {

        $location = $_.DirectoryName
        $resourceOutPath = Join-Path -Path $location -ChildPath $outputPath

        $cshtmls = Get-Childitem -Path $location -Include "*.cshtml" -Recurse

        if ($cshtmls.Length -gt 0) {
            $exists = Test-Path $resourceOutPath
            If (-not $exists) {
                New-Item -ItemType Directory -Path $resourceOutPath
            }
        }

        foreach ($cshtml in $cshtmls) {

            $fileContent = Get-Content $cshtml -Encoding UTF8

            $outFileName = $cshtml.Name.TrimEnd('cshtml') + "key"

            $sourcePath = $cshtml.Directory.FullName
            $sourcePath = $sourcePath.Remove(0, $location.Length)

            $locFilePath = Join-Path -Path $resourceOutPath -ChildPath $sourcePath $outFileName

            If (Test-Path $locFilePath) {
                Remove-Item -Path $locFilePath
            }

            $varName = $fileContent |
            Select-String '@inject.*IViewLocalizer *(\w*) {0,}$' -AllMatches |
            Foreach-Object { $_.Matches } |
            Foreach-Object { $_.Groups[1].Value }

            $localizerKeyExtractor = '@' + $varName + '\["(.*?)"\]'

            $fileContent | Select-String $localizerKeyExtractor -AllMatches | Foreach-Object { $_.Matches } | Foreach-Object { $_.Groups[1].Value | Out-File -FilePath $locFilePath -Append -Encoding utf8 }

            $filesCreated += $locFilePath
        }
    }
    return $filesCreated
}

function RemoveFiles {
    param($filesCreated)

    foreach ($item in $filesCreated) {
        Remove-Item -Path $item
    }
}

function LoadKeysFromResx {
    param ([Parameter(Mandatory = $true)]
        $resxPath
    )

    $keys = @()

    [xml]$doc = get-content $resxPath

    foreach ($d in $doc.GetElementsByTagName("data")) {
        [System.Xml.XmlElement]$element = $d
        [System.Xml.XmlAttribute]$attribute = $element.Attributes.GetNamedItem("name");

        if ($attribute) {
            $keys += $element.Attributes.GetNamedItem("name").Value
        }
    }

    return $keys
}

function ResxGenerator {
    param([Parameter(Mandatory = $true)] $lang)

    Get-Childitem -Path . -Include "*.key" -Recurse | ForEach-Object {

        $keyFile = $_

        foreach ($i in $lang) {

            $keys = @()
            $l = $i

            $resx = $keyFile.FullName.Replace(".key", ".$l.resx")
            $l = $i.ToUpper()

            # TODO: udpate logic
            if (Test-Path $resx) {
                $keys = LoadKeysFromResx($resx)
            }
            else {
                Copy-Item -Path $template -Destination $resx -Force
            }

            Write-Host $resx

            [xml]$doc = get-content $resx
            Get-Content $keyFile | ForEach-Object {
                if (!$keys.Contains($_)) {

                    $data = $doc.CreateNode("element", "data", "")
                    $data.SetAttribute("name", $_)
                    $data.SetAttribute("xml:space", "preserve")
                    $value = $doc.CreateNode("element", "value", "")
                    if ($i -eq $defaultLang) {
                        $value.InnerText = $_
                    }
                    else {
                        $value.InnerText = $_ + " " + $l
                    }
                    $data.AppendChild($value)
                    $doc.root.AppendChild($data)

                    $keys += $_
                }
            }

            $doc.Save($resx)
        }
    }
}

$keyFiles = CollectLocalizationKeys

$lang = $langageCodes.Split(", ")
ResxGenerator $lang

RemoveFiles($keyFiles)
