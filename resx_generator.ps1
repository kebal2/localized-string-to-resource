$template = ".\blank.resx";

Get-Childitem -Path . -Include "*.key" -Recurse | ForEach-Object {

    $keyFile = $_

    $resx = $keyFile.FullName.Replace(".key", ".hu.resx")

    Write-Host $resx
    Copy-Item -Path $template -Destination $resx -Force
    
    [xml]$doc = get-content $resx
    Get-Content $keyFile | ForEach-Object { 
    
        $data = $doc.CreateNode("element", "data", "")
        $data.SetAttribute("name", $_)
        $data.SetAttribute("xml:space", "preserve")
        $value = $doc.CreateNode("element", "value", "")
        $value.InnerText = $_
        $data.AppendChild($value)
        $doc.root.AppendChild($data)
    }
    
    $doc.Save($resx)

}

#
#<data name="BankAccountNumber" xml:space="preserve">
#<value>A {0} mezőbe írt bankszámlaszám érvénytelen.</value>
#</data>

#