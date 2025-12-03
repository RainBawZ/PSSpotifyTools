Function Get-SpotifyToken {
    <#
        .SYNOPSIS
        Obtains a valid Spotify OAuth token.

        .DESCRIPTION
        This function retrieves a valid Spotify OAuth token, either by refreshing
        an existing token or by performing the full PKCE authorization flow.

        .PARAMETER ClientId
        The Spotify client ID.

        .PARAMETER RedirectUri
        The redirect URI for the OAuth flow.

        .PARAMETER Scopes
        The scopes to request for the OAuth token.

        .OUTPUTS
        [PSCustomObject] A valid Spotify OAuth token.

        .EXAMPLE
        $Token = Get-SpotifyToken -ClientId $ClientId -RedirectUri $RedirectUri -Scopes $Scopes
        Obtains a valid Spotify OAuth token.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    Param (
        # Spotify client ID
        [String]$ClientId    = $SCRIPT:ClientId,

        # OAuth redirect URI
        [String]$RedirectUri = $SCRIPT:RedirectUri,

        # Scopes to request
        [String[]]$Scopes    = $SCRIPT:Scopes
    ) # Param

    # Try to load existing token
    [PSCustomObject]$Token = Import-Token

    # Validate token
    If ($Token -And $Token.refresh_token -And $Token.expires_at) {

        [Int64]$Now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() # Current time in seconds

        If ($Now -lt $Token.expires_at - 60) {Return $Token} # Still valid (60s skew)

        # Refresh Token Flow
        [Hashtable]$Body = @{
            grant_type    = 'refresh_token'
            refresh_token = $Token.refresh_token
            client_id     = $ClientId
        } # Hashtable

        # Invoke token refresh
        [PSCustomObject]$Response = Invoke-RestMethod -Method POST -Uri "$SCRIPT:AccountsBase/api/token" -Body $Body -ErrorAction SilentlyContinue

        # Check for errors
        [PSCustomObject]$NewToken = @{
            access_token  = $Response.access_token
            token_type    = $Response.token_type
            scope         = $Response.scope
            expires_in    = $Response.expires_in
            refresh_token = ($Response.refresh_token ? $Response.refresh_token : $Token.refresh_token) # Use new refresh token if provided
            expires_at    = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + $Response.expires_in # New expiry time
        } # PSCustomObject

        # Export new token
        Export-Token $NewToken 

        Return $NewToken
    } # If
    
    # PKCE Authorization Flow
    [String]$CodeVerifier  = New-CodeVerifier # Generate code verifier
    [String]$CodeChallenge = Get-CodeChallenge $CodeVerifier # Compute code challenge
    [String]$State         = [Guid]::NewGuid().ToString('N') # Generate state parameter
    [String]$Scope         = $Scopes -Join ' ' # Join scopes

    # Build authorization URL
    [String]$AuthParams = @(
        "client_id=$ClientId",
        'response_type=code',
        "redirect_uri=$([Uri]::EscapeDataString($RedirectUri))",
        'code_challenge_method=S256',
        "code_challenge=$([Uri]::EscapeDataString($CodeChallenge))",
        "state=$State",
        "scope=$([Uri]::EscapeDataString($Scope))"
    ) -Join '&'
    [String]$AuthUrl = "$SCRIPT:AccountsBase/authorize?$AuthParams"

    # Start local listener on the RedirectUri prefix (must end with "/")
    [String]$Prefix             = $RedirectUri.TrimEnd('/') + '/'
    [Net.HttpListener]$Listener = Start-LocalListener $Prefix

    Try {
        Write-Host -ForegroundColor Cyan 'Opening browser for Spotify authorization...'
        Start-Process $AuthUrl # Open browser for user authorization

        [Net.HttpListenerContext]$Context = $Listener.GetContext() # Wait for redirect

        # Parse query parameters
        [Collections.Specialized.NameValueCollection]$Query = [Web.HttpUtility]::ParseQueryString($Context.Request.Url.Query)

        # Validate response
        If ($Query['state'] -ne $State) {Throw 'OAuth state mismatch.'}
        If ($Query['error'])            {Throw "Spotify authorization error: $($Query['error'])"}
        
        # Success - respond to browser
        Write-OkHtml $Context.Response 'Authorization complete.'

        # Exchange authorization code for tokens
        [Hashtable]$Body = @{
            grant_type    = 'authorization_code'
            code          = $Query['code']
            redirect_uri  = $RedirectUri
            client_id     = $ClientId
            code_verifier = $CodeVerifier
        } # Hashtable

        # Invoke token exchange
        [PSCustomObject]$Response = Invoke-RestMethod -Method POST -Uri "$SCRIPT:AccountsBase/api/token" -Body $Body

        # Build token object
        [PSCustomObject]$Token = @{
            access_token  = $Response.access_token
            token_type    = $Response.token_type
            scope         = $Response.scope
            expires_in    = $Response.expires_in
            refresh_token = $Response.refresh_token
            expires_at    = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + $Response.expires_in # Expiry time
        } # PSCustomObject

        # Export token
        Export-Token $Token

        Return $Token
    } # Try
    Finally {
        # Stop local listener
        Stop-LocalListener $Listener
    } # Finally
} # Function Get-SpotifyToken
