# Use the following commands to bind/unbind SSL cert
# netsh http add sslcert ipport=0.0.0.0:443 certhash=3badca4f8d38a85269085aba598f0a8a51f057ae "appid={00112233-4455-6677-8899-AABBCCDDEEFF}"
# netsh http delete sslcert ipport=0.0.0.0:443 
$HttpListener = New-Object System.Net.HttpListener
$HttpListener.Prefixes.Add("http://+:80/")
$HttpListener.Prefixes.Add("https://+:443/")
$HttpListener.Start()
While ($HttpListener.IsListening) {
	$Result = 0
    $HttpContext = $HttpListener.GetContext()
    $HttpRequest = $HttpContext.Request
    $RequestUrl = $HttpRequest.Url.OriginalString
    Write-Host "$RequestUrl"
    if($HttpRequest.HasEntityBody) {
      $Reader = New-Object System.IO.StreamReader($HttpRequest.InputStream)
      # $json = $Reader.ReadToEnd() | ConvertFrom-Json 
	  $json = $Reader.ReadToEnd() 

	  Write-Host Param: $json
	  if($json -match '.*mode=(?<Mode>.+)')
			{
				 $Mode = $Matches.Mode
				 Write-Host mode: $Mode
				 & ../Run.ps1 -mode $Mode
				 $Result = $LASTEXITCODE
				
			}
    }
    $HttpResponse = $HttpContext.Response
    $HttpResponse.Headers.Add("Content-Type","application/json")
    $HttpResponse.Headers.Add("Access-Control-Allow-Origin","http://localhost:8080")
    $HttpResponse.StatusCode = 200
    $jsondata = "{ExitCode:$Result}" | ConvertTo-Json
    $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($jsondata)
    $HttpResponse.ContentLength64 = $ResponseBuffer.Length
    $HttpResponse.OutputStream.Write($ResponseBuffer,0,$ResponseBuffer.Length)
    $HttpResponse.Close()
    Write-Output "" # Newline
}
$HttpListener.Stop()