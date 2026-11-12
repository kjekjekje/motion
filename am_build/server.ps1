$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:8765/")
$l.Start()
while ($l.IsListening) {
  $ctx = $l.GetContext(); $rq = $ctx.Request; $rs = $ctx.Response
  try {
    $p = $rq.Url.AbsolutePath.TrimStart('/')
    if ($rq.HttpMethod -eq 'POST' -and $p -eq 'upload') {
      $ext = $rq.QueryString['ext']; if (-not $ext) { $ext = 'webm' }
      $out = Join-Path (Split-Path $root -Parent) ("AsianMission_30s_9x16." + $ext)
      $fs = [IO.File]::Create($out); $rq.InputStream.CopyTo($fs); $fs.Close()
      $b = [Text.Encoding]::UTF8.GetBytes("ok"); $rs.OutputStream.Write($b,0,$b.Length); $rs.Close()
      Write-Output "saved $out"; continue
    }
    if ($p -eq '') { $p = 'index.html' }
    $f = Join-Path $root $p
    if (Test-Path $f) {
      $rs.ContentType = @{'.html'='text/html; charset=utf-8';'.wav'='audio/wav';'.mp3'='audio/mpeg'}[[IO.Path]::GetExtension($f)]
      $b = [IO.File]::ReadAllBytes($f); $rs.OutputStream.Write($b,0,$b.Length)
    } else { $rs.StatusCode = 404 }
  } catch {}
  $rs.Close()
}
