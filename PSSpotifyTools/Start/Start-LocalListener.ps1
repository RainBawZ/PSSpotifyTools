Function Start-LocalListener {
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
    [CmdletBinding()]
    [OutputType([Net.HttpListener])]

    Param (
        # Prefix to listen on
        [Parameter(Mandatory)]
        [String]$Prefix
    ) # Param

    # Create and start listener
    [Net.HttpListener]$Listener = [Net.HttpListener]::New()

    # Add prefix and start
    $Listener.Prefixes.Add($Prefix)
    $Listener.Start()

    Return $Listener
} # Function Start-LocalListener
