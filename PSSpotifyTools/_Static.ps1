[PSCustomObject]$Encoding     = @{}
[Collections.IDictionary]$Enc = @{}
$Enc.Add('UTF8', [Text.UTF8Encoding]::New($False))
$Enc.Add('ASCII', [Text.ASCIIEncoding]::New())
$Encoding | Add-Member -NotePropertyMembers $Enc

[PSCustomObject]$Api              = @{}
[Collections.IDictionary]$ApiData = @{}
$ApiData.Add('TokenPath', "$PSScriptRoot\spotify_token.json")
$ApiData.Add('AccountsBase', 'https://accounts.spotify.com')
$ApiData.Add('RedirectUri', 'http://localhost:13370/callback')
$ApiData.Add('Scopes', @('user-read-playback-state', 'user-read-currently-playing'))
$ApiData.Add('ClientId', '')
$Api | Add-Member -NotePropertyMembers $ApiData

[PSCustomObject]$GLOBAL:PSSpotifyTools = @{}
[Collections.IDictionary]$Root = @{}
$Root.Add('Encoding', $Encoding)
$Root.Add('API', $Api)
$GLOBAL:PSSpotifyTools | Add-Member -NotePropertyMembers $Root
