param([string]$Voice = "ko-KR-SunHiNeural", [string]$Rate = "+0%")
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$lines = @(
"선교사의 든든한 동반자, 아시안미션.",
"후원금의 100%를, 선교사와 사역지에 전달합니다.",
"지난 한 해, 3,063명의 선교사와 협력하고, 85억 원을 지원했습니다.",
"힐링 바우처, 선교관, 건강검진으로 쉼과 회복을 돕습니다.",
"국내외 모든 사역자를 위한 멤버케어.",
"복음의 씨앗, AM이 함께 심습니다."
)
$TOKEN = "6A5AA1D4EAFF4E9FB37E23D68491D6F4"
function Gec {
  $sec = [long]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) + 11644473600
  $sec = $sec - ($sec % 300)
  $ticks = [decimal]$sec * 10000000
  $sha = [Security.Cryptography.SHA256]::Create()
  ($sha.ComputeHash([Text.Encoding]::ASCII.GetBytes("$ticks$TOKEN")) | % { $_.ToString("X2") }) -join ''
}
function Ts { [DateTime]::UtcNow.ToString("ddd MMM dd yyyy HH:mm:ss 'GMT+0000 (Coordinated Universal Time)'", [Globalization.CultureInfo]::InvariantCulture) }
function SendText($ws, $s) {
  $b = [Text.Encoding]::UTF8.GetBytes($s)
  $ws.SendAsync([ArraySegment[byte]]::new($b), 'Text', $true, [Threading.CancellationToken]::None).Wait()
}
$i = 0
foreach ($t in $lines) {
  $ws = New-Object Net.WebSockets.ClientWebSocket
  $ws.Options.SetRequestHeader("Origin", "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold")
  $ws.Options.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36 Edg/130.0.0.0")
  $cid = [guid]::NewGuid().ToString("N")
  $uri = "wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1?TrustedClientToken=$TOKEN&Sec-MS-GEC=$(Gec)&Sec-MS-GEC-Version=1-130.0.2849.68&ConnectionId=$cid"
  $ws.ConnectAsync([Uri]$uri, [Threading.CancellationToken]::None).Wait()
  SendText $ws ("X-Timestamp:$(Ts)`r`nContent-Type:application/json; charset=utf-8`r`nPath:speech.config`r`n`r`n" + '{"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"false"},"outputFormat":"audio-24khz-96kbitrate-mono-mp3"}}}}')
  $esc = [Security.SecurityElement]::Escape($t)
  $ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='ko-KR'><voice name='$Voice'><prosody pitch='+0Hz' rate='$Rate' volume='+0%'>$esc</prosody></voice></speak>"
  SendText $ws ("X-RequestId:$cid`r`nContent-Type:application/ssml+xml`r`nX-Timestamp:$(Ts)Z`r`nPath:ssml`r`n`r`n" + $ssml)
  $out = New-Object IO.MemoryStream
  $buf = New-Object byte[] 65536
  $done = $false
  while (-not $done) {
    $msg = New-Object IO.MemoryStream
    do {
      $r = $ws.ReceiveAsync([ArraySegment[byte]]::new($buf), [Threading.CancellationToken]::None).Result
      $msg.Write($buf, 0, $r.Count)
    } while (-not $r.EndOfMessage)
    $data = $msg.ToArray()
    if ($r.MessageType -eq 'Close') { break }
    if ($r.MessageType -eq 'Text') {
      if ([Text.Encoding]::UTF8.GetString($data) -match 'Path:turn.end') { $done = $true }
    } else {
      $hl = $data[0] * 256 + $data[1]
      if ($data.Length -gt 2 + $hl) { $out.Write($data, 2 + $hl, $data.Length - 2 - $hl) }
    }
  }
  [IO.File]::WriteAllBytes("$dir\vo$i.mp3", $out.ToArray())
  "$i $($out.Length) bytes  ~$([math]::Round($out.Length/12000,2))s"
  try { $ws.Abort() } catch {}
  $i++
}
