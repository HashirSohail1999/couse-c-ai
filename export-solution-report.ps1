param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Destination
)
$ErrorActionPreference = 'Stop'
$ascii = [Text.Encoding]::ASCII
$reportTitle = ([IO.File]::ReadLines($Source) | Select-Object -First 1) -replace '^# ', ''
$pages = New-Object 'System.Collections.Generic.List[string]'
$page = New-Object Text.StringBuilder
$y = 788
function Escape-Pdf([string]$value) {
    $value.Replace('\','\\').Replace('(','\(').Replace(')','\)')
}
function Finish-Page {
    $number = $pages.Count + 1
    $footer = Escape-Pdf "Squad Sutskever | $reportTitle | Page $number"
    $null = $page.Append("0.40 0.45 0.50 rg BT /F1 8 Tf 48 28 Td ($footer) Tj ET`n")
    $pages.Add($page.ToString())
    $null = $page.Clear()
    $script:y = 788
}
foreach ($line in [IO.File]::ReadAllLines($Source)) {
    if ($line -eq '') { $y -= 7; continue }
    $heading = $line -match '^(#{1,3}) '
    $font = 'F1'; $size = 10; $leading = 14; $width = 94
    if ($heading) {
        $level = $Matches[1].Length
        $size = @(0,19,14,11)[$level]
        $font = 'F2'; $leading = $size + 6
        $width = [int](490 / ($size * 0.57))
        $line = $line -replace '^#{1,3} ', ''
        $y -= 8
        if ($y -lt 115) { Finish-Page }
    } elseif ($line -match '^Configuration |^(MHA|GQA|MQA) \(' -or $line.StartsWith('python ')) {
        $font = 'F3'; $size = 8.3; $leading = 12; $width = 99
    }
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $remaining = $line
    while ($remaining.Length -gt $width) {
        $cut = $remaining.LastIndexOf(' ', $width)
        if ($cut -lt 1) { $cut = $width }
        $lines.Add($remaining.Substring(0,$cut))
        $remaining = $remaining.Substring($cut).TrimStart()
    }
    $lines.Add($remaining)
    foreach ($wrapped in $lines) {
        if ($y -lt 55) { Finish-Page }
        $colour = if ($heading) { '0.10 0.24 0.35' } else { '0.12 0.14 0.17' }
        $escaped = Escape-Pdf $wrapped
        $null = $page.Append("$colour rg BT /$font $size Tf 48 $y Td ($escaped) Tj ET`n")
        $y -= $leading
    }
}
if ($page.Length -gt 0) { Finish-Page }
$objects = New-Object 'System.Collections.Generic.List[string]'
$objects.Add('<< /Type /Catalog /Pages 2 0 R >>')
$kids = for ($i=0; $i -lt $pages.Count; $i++) { "$(6 + 2*$i) 0 R" }
$objects.Add("<< /Type /Pages /Count $($pages.Count) /Kids [ $($kids -join ' ') ] >>")
$objects.Add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>')
$objects.Add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>')
$objects.Add('<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>')
for ($i=0; $i -lt $pages.Count; $i++) {
    $contentId = 7 + 2*$i
    $objects.Add("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R >> >> /Contents $contentId 0 R >>")
    $content = $pages[$i]
    $objects.Add("<< /Length $($ascii.GetByteCount($content)) >>`nstream`n$content" + "endstream")
}
$pdf = New-Object Text.StringBuilder
$null = $pdf.Append("%PDF-1.4`n")
$offsets = New-Object 'System.Collections.Generic.List[int]'
for ($i=0; $i -lt $objects.Count; $i++) {
    $offsets.Add($ascii.GetByteCount($pdf.ToString()))
    $null = $pdf.Append("$($i+1) 0 obj`n$($objects[$i])`nendobj`n")
}
$xref = $ascii.GetByteCount($pdf.ToString())
$null = $pdf.Append("xref`n0 $($objects.Count+1)`n0000000000 65535 f `n")
foreach ($offset in $offsets) { $null = $pdf.Append($offset.ToString('0000000000') + " 00000 n `n") }
$null = $pdf.Append("trailer`n<< /Size $($objects.Count+1) /Root 1 0 R >>`nstartxref`n$xref`n%%EOF`n")
[IO.File]::WriteAllBytes($Destination,$ascii.GetBytes($pdf.ToString()))
Write-Output "Created $Destination ($($pages.Count) pages)"
