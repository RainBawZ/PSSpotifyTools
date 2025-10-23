$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop

#---- Helper Functions ----
Function ConvertTo-Base64Url {
    [CmdletBinding()]
    [OutputType([String])]

    <#
        .SYNOPSIS
        Converts a byte array to a base64url-encoded string.

        .DESCRIPTION
        This function takes a byte array and encodes it using base64url encoding,
        which is a URL-safe variant of base64 encoding. It removes padding characters
        and replaces certain characters to make the string URL-safe.

        .PARAMETER Bytes
        The byte array to be converted.

        .OUTPUTS
        [String] A base64url-encoded string.

        .EXAMPLE
        $Bytes = [Byte[]](0..255)
        ConvertTo-Base64Url -Bytes $Bytes
        Converts the byte array to a base64url-encoded string.
    #>

    Param (
        # Bytes parameter
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Byte[]]$Bytes
    )

    # Convert byte array to base64url string
    [String]$Base64Url = [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_') # Base64url encoding

    Return $Base64Url
}

Function New-CodeVerifier {
    [CmdletBinding()]
    [OutputType([String])]

    <#
        .SYNOPSIS
        Generates a new code verifier for PKCE.

        .DESCRIPTION
        This function generates a random 64-byte code verifier and encodes it in base64url format.
        64 bytes provides sufficient entropy for PKCE as per RFC 7636.

        .OUTPUTS
        [String] A base64url-encoded code verifier.

        .EXAMPLE
        New-CodeVerifier
        Generates and returns a new code verifier.
    #>
 
    # Generate empty byte array
    [Byte[]]$RndBytes = [Byte[]]::New(64)

    # Fill byte array with cryptographically secure random bytes
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($RndBytes)

    # Convert filled byte array to base64url string
    [String]$Base64Url = ConvertTo-Base64Url $RndBytes

    Return $Base64Url
}

Function Get-CodeChallenge {
    [CmdletBinding()]
    [OutputType([String])]

    <#
        .SYNOPSIS
        Computes the code challenge from a code verifier for PKCE.

        .DESCRIPTION
        This function takes a code verifier string, computes its SHA-256 hash,
        and encodes the result in base64url format to produce the code challenge.

        .PARAMETER CodeVerifier
        The code verifier string.

        .OUTPUTS
        [String] A base64url-encoded code challenge.

        .EXAMPLE
        $CodeVerifier = 'example_code_verifier'
        Get-CodeChallenge -CodeVerifier $CodeVerifier
        Computes and returns the code challenge for the given code verifier.
    #>

    Param (
        # CodeVerifier parameter
        [Parameter(Mandatory)]
        [String]$CodeVerifier
    )

    # Compute SHA-256 hash
    [Byte[]]$CodeVerifierBytes = $SCRIPT:Ascii.GetBytes($CodeVerifier) # ASCII encoding
    [Byte[]]$HashBytes         = [Security.Cryptography.SHA256]::Create().ComputeHash($CodeVerifierBytes) # SHA-256 hash
    [String]$Base64UrlHash     = ConvertTo-Base64Url $HashBytes # Base64url encode

    Return $Base64UrlHash
}

Function Start-LocalListener {
    [CmdletBinding()]
    [OutputType([Net.HttpListener])]

    <#
        .SYNOPSIS
        Starts a local HTTP listener on the specified prefix.

        .DESCRIPTION
        This function creates and starts an HTTP listener that listens for incoming HTTP requests
        on the specified URL prefix.

        .PARAMETER Prefix
        The URL prefix to listen on (e.g., "http://localhost:13370/callback/").

        .OUTPUTS
        [Net.HttpListener] The started HTTP listener.

        .EXAMPLE
        $Listener = Start-LocalListener -Prefix "http://localhost:13370/callback/"
        Starts an HTTP listener on the specified prefix.
    #>

    Param (
        # Prefix parameter
        [Parameter(Mandatory)]
        [String]$Prefix
    )

    # Create and start listener
    [Net.HttpListener]$Listener = [Net.HttpListener]::New()

    # Add prefix and start
    $Listener.Prefixes.Add($Prefix)
    $Listener.Start()

    Return $Listener
}

Function Stop-LocalListener {
    [CmdletBinding()]
    [OutputType([Void])]

    <#
        .SYNOPSIS
        Stops and closes the specified HTTP listener.

        .DESCRIPTION
        This function stops the given HTTP listener and releases its resources.

        .PARAMETER Listener
        The HTTP listener to stop.

        .OUTPUTS
        [Void]

        .EXAMPLE
        Stop-LocalListener -Listener $Listener
        Stops and closes the specified HTTP listener.
    #>

    Param (
        # Listener parameter
        [Parameter(Mandatory)]
        [Net.HttpListener]$Listener
    )

    # Stop and close listener
    $Listener.Stop()
    $Listener.Close()
}

Function Write-OkHtml {
    [CmdletBinding()]
    [OutputType([Void])]

    <#
        .SYNOPSIS
        Writes a simple HTML response indicating success.

        .DESCRIPTION
        This function sends an HTML response to the specified HTTP listener response,
        displaying a message and indicating that the user may close the tab.

        .PARAMETER Response
        The HTTP listener response to write to.

        .PARAMETER Message
        The message to display in the HTML response.

        .OUTPUTS
        [Void]

        .EXAMPLE
        Write-OkHtml -Response $Response -Message "Authorization complete."
        Sends an HTML response indicating that authorization is complete.
    #>

    Param (
        # Response parameter
        [Parameter(Mandatory, Position = 0)]
        [Net.HttpListenerResponse]$Response,

        # Message parameter
        [Parameter(Mandatory, Position = 1)]
        [String]$Message
    )

    # Build HTML content
    [String]$Html      = "<html><body style='font-family:system-ui;'><h2>$Message</h2>You may close this tab.</body></html>" # Raw HTML
    [Byte[]]$HtmlBytes = $SCRIPT:Utf8.GetBytes($Html) # Encode to UTF8 bytes

    # Write response
    $Response.ContentLength64 = $HtmlBytes.Count # Set content length
    $Response.OutputStream.Write($HtmlBytes, 0, $HtmlBytes.Count) # Write content
    $Response.OutputStream.Close() # Close stream
}

Function Export-Token {
    [CmdletBinding()]
    [OutputType([Void])]

    <#
        .SYNOPSIS
        Exports the specified token to a file.

        .DESCRIPTION
        This function serializes the given token object and writes it to a file
        in the specified token directory.

        .PARAMETER Token
        The token object to export.

        .OUTPUTS
        [Void]

        .EXAMPLE
        Export-Token -Token $Token
        Exports the specified token to a file.
    #>

    Param (
        # Token parameter
        [Parameter(Mandatory, Position = 0)]
        [PSCustomObject]$Token,

        # File parameter
        [Parameter(Position = 1)]
        [ValidateScript({$_.Directory.Exists})] # Ensure directory exists
        [IO.FileInfo]$File = $SCRIPT:TokenPath
    )

    # Check if directory exists
    If (!$File.Directory.Exists) {Throw [IO.DirectoryNotFoundException]::New("Token directory not found: $($File.Directory.FullName)")}

    # Serialize token to JSON
    [String]$Json = ConvertTo-Json -InputObject $Token -Depth 100 -Compress

    # Write to file
    [IO.File]::WriteAllText($File, $Json, $SCRIPT:Utf8)
}

Function Import-Token {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    <#
        .SYNOPSIS
        Imports a token from a file.

        .DESCRIPTION
        This function reads the token file, deserializes its content,
        and returns the token object.

        .PARAMETER File
        The file from which to import the token.

        .OUTPUTS
        [PSCustomObject] The imported token object.

        .EXAMPLE
        $Token = Import-Token
        Imports the token from the default token file.
    #>

    Param (
        # File parameter
        [ValidateScript({$_.Exists})] # Ensure file exists
        [IO.FileInfo]$File = $SCRIPT:TokenPath
    )

    # Check if file exists
    If (!$File.Exists) {Throw [IO.FileNotFoundException]::New("Token file not found: $($File.FullName)")}

    # Read and parse token
    [Byte[]]$TokenBytes  = [IO.File]::ReadAllBytes($File.FullName) # Read file bytes
    [String]$TokenString = $SCRIPT:Utf8.GetString($TokenBytes) # Decode to string

    # Parse JSON
    [PSCustomObject]$Token = ConvertFrom-Json -InputObject $TokenString -Depth 100

    Return $Token
}

Function Get-SpotifyToken {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

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

    Param (
        # ClientId parameter
        [String]$ClientId    = $SCRIPT:ClientId,

        # RedirectUri parameter
        [String]$RedirectUri = $SCRIPT:RedirectUri,

        # Scopes parameter
        [String[]]$Scopes    = $SCRIPT:Scopes
    )

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
        }

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
        }

        # Export new token
        Export-Token $NewToken 

        Return $NewToken
    }

    # Full PKCE Authorization Flow
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
        }

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
        }

        # Export token
        Export-Token $Token

        Return $Token
    }
    Finally {
        # Stop local listener
        Stop-LocalListener $Listener
    }
}

Function Invoke-SpotifyApi {
    [CmdletBinding(DefaultParameterSetName = 'NoMethod')]
    [OutputType([PSCustomObject])]

    <#
        .SYNOPSIS
        Invokes a Spotify Web API endpoint.

        .DESCRIPTION
        This function sends an HTTP request to the specified Spotify Web API endpoint
        using the provided method, path, query parameters, and body. It handles
        authentication by obtaining a valid OAuth token.

        .PARAMETER Method
        The HTTP method to use (GET, POST, PUT, DELETE). Default is GET.

        .PARAMETER Path
        The API endpoint path (e.g., '/me/player').

        .PARAMETER Query
        A hashtable of query parameters to include in the request.

        .PARAMETER Body
        A PSCustomObject representing the JSON body to include in the request.

        .OUTPUTS
        [PSCustomObject] The response from the Spotify Web API.

        .EXAMPLE
        $Response = Invoke-SpotifyApi -Path '/me/player'
        Sends a GET request to the '/me/player' endpoint and returns the response.
    #>

    Param (
        # Method parameter
        [Parameter(Position = 0, ParameterSetName = 'wMethod')]
        [Parameter(Position = 1, ParameterSetName = 'NoMethod')]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE')] # Allowed methods
        [String]$Method = 'GET',

        # Path parameter
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'NoMethod')]
        [Parameter(Mandatory, Position = 1, ParameterSetName = 'wMethod')]
        [String]$Path,

        # Query parameter
        [Hashtable]$Query,

        # Body parameter
        [PSCustomObject]$Body
    )

    # Get OAuth token
    [PSCustomObject]$Token = Get-SpotifyToken -ClientId $SCRIPT:ClientId -RedirectUri $SCRIPT:RedirectUri -Scopes $SCRIPT:Scopes

    [String]$Uri = "$SCRIPT:ApiBase$Path"

    # Append query string if provided
    If ($Query) {
        # Build query string
        [Collections.Specialized.NameValueCollection]$QueryString = [Web.HttpUtility]::ParseQueryString('')

        # Populate query string
        ForEach ($Entry in $Query.GetEnumerator()) {$QueryString[$Entry.Key] = [String]$Query[$Entry.Value]}
        
        # Append to URI
        $Uri += '?' + $QueryString.ToString()
    }

    # Prepare Invoke-RestMethod parameters
    [Hashtable]$IrmParams = @{
        Uri     = $Uri
        Method  = $Method
        Headers = [Collections.IDictionary]@{Authorization = "Bearer $($Token.access_token)"}
    }

    # Add body if provided
    If ($Body) {
        $IrmParams['Body'] = ConvertTo-Json -InputObject $Body -Depth 100 -Compress # Serialize body
        $IrmParams['Headers'].Add('Content-Type', 'application/json') # Set content type header
    }

    # Invoke the Spotify API
    [PSCustomObject]$Response = Invoke-RestMethod @IrmParams

    Return $Response
}

# ---- High level calls ----
Function Get-SpotifyPlaybackState {
    # Retrieves the current playback state from Spotify.
    Invoke-SpotifyApi GET -Path '/me/player'
}

Function Get-SpotifyQueue {
    # Retrieves the current playback queue from Spotify.
    Invoke-SpotifyApi GET -Path '/me/player/queue'
}

# ---- Script-level constants ----
[Text.Encoding]$Utf8    = [Text.UTF8Encoding]::New($False) # No BOM
[Text.Encoding]$Ascii   = [Text.ASCIIEncoding]::New() # ASCII encoding
[IO.FileInfo]$TokenPath = "$PSScriptRoot\spotify_token.json" # Token file path
[String]$AccountsBase   = 'https://accounts.spotify.com' # Spotify Accounts service base URL
[String]$ApiBase        = 'https://api.spotify.com/v1'   # Spotify Web API base URL
[String]$RedirectUri    = 'http://localhost:13370/callback' # Redirect URI for OAuth flow
[String[]]$Scopes       = @('user-read-playback-state', 'user-read-currently-playing') # Required OAuth scopes

[String]$ClientId = <#your client id#> # Spotify Client ID for OBS Spotify plugin

# ---- End of Script ----