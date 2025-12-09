# Extract all impulse.Config properties from impulse-reforged framework
$frameworkPath = "S:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\gamemodes\impulse-reforged"
$outputFile = "S:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\gamemodes\impulse-reforged\config_properties.txt"

# Find all .lua files
$luaFiles = Get-ChildItem -Path $frameworkPath -Filter "*.lua" -Recurse

# Regex pattern to match impulse.Config.PropertyName
$pattern = 'impulse\.Config\.([A-Za-z_][A-Za-z0-9_]*)'

# HashSet to store unique config properties
$configProperties = @{}

Write-Host "Scanning $($luaFiles.Count) Lua files..." -ForegroundColor Cyan

foreach ($file in $luaFiles) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $matches = [regex]::Matches($content, $pattern)
        foreach ($match in $matches) {
            $propertyName = $match.Groups[1].Value
            if ($propertyName -ne "YML") {  # Skip the YML property as it's a special case
                if (-not $configProperties.ContainsKey($propertyName)) {
                    $configProperties[$propertyName] = @()
                }
                # Store file reference
                $relPath = $file.FullName.Replace($frameworkPath, "").TrimStart('\')
                if ($configProperties[$propertyName] -notcontains $relPath) {
                    $configProperties[$propertyName] += $relPath
                }
            }
        }
    }
}

# Sort and write to file
$sortedProperties = $configProperties.Keys | Sort-Object

Write-Host "`nFound $($sortedProperties.Count) unique config properties" -ForegroundColor Green
Write-Host "Writing to: $outputFile" -ForegroundColor Yellow

$output = @()
$output += "======================================================"
$output += "impulse.Config Properties Found in impulse-reforged"
$output += "======================================================"
$output += ""
$output += "Total: $($sortedProperties.Count) properties"
$output += ""
$output += "------------------------------------------------------"
$output += ""

foreach ($prop in $sortedProperties) {
    $output += "impulse.Config.$prop"
    $output += "  Used in: $($configProperties[$prop].Count) file(s)"
    # Show first 3 file references
    $fileRefs = $configProperties[$prop] | Select-Object -First 3
    foreach ($fileRef in $fileRefs) {
        $output += "    - $fileRef"
    }
    if ($configProperties[$prop].Count -gt 3) {
        $output += "    ... and $($configProperties[$prop].Count - 3) more"
    }
    $output += ""
}

$output | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`nComplete! Results saved to config_properties.txt" -ForegroundColor Green
Write-Host "`nFirst 20 properties found:" -ForegroundColor Cyan
$sortedProperties | Select-Object -First 20 | ForEach-Object { Write-Host "  - impulse.Config.$_" }
