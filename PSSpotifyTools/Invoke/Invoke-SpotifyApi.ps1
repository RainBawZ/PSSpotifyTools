Function Invoke-SpotifyApi {
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
        A PSCustomObject representing the body to include in the request.

        .OUTPUTS
        [PSCustomObject] The response from the Spotify Web API.

        .EXAMPLE
        PS> $PlaybackState = Invoke-SpotifyApi -Path '/me/player'
        Gets current playback state.

        .EXAMPLE
        PS> $Queue = Invoke-SpotifyApi -Path '/me/player/queue'
        Gets current playback queue.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NoMethod')]
    [OutputType([PSCustomObject])]

    Param (
        # HTTP method for request
        [Parameter(Position = 0, ParameterSetName = 'wMethod')]
        [Parameter(Position = 1, ParameterSetName = 'NoMethod')]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE')] # Allowed methods
        [String]$Method = 'GET',

        # API endpoint path
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'NoMethod')]
        [Parameter(Mandatory, Position = 1, ParameterSetName = 'wMethod')]
        [String]$Path,

        # URL query parameters
        [Hashtable]$Query,

        # Request body
        [PSCustomObject]$Body
    ) # Param

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
    } # If

    # Prepare Invoke-RestMethod parameters
    [Hashtable]$IrmParams = @{
        Uri     = $Uri
        Method  = $Method
        Headers = [Collections.IDictionary]@{Authorization = "Bearer $($Token.access_token)"}
    } # Hashtable

    # Add body if provided
    If ($Body) {
        $IrmParams['Body'] = ConvertTo-Json -InputObject $Body -Depth 100 -Compress # Serialize body
        $IrmParams['Headers'].Add('Content-Type', 'application/json') # Set content type header
    } # If

    # Invoke the Spotify API
    [PSCustomObject]$Response = Invoke-RestMethod @IrmParams

    Return $Response
} # Function Invoke-SpotifyApi
