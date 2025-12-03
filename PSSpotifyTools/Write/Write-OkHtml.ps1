Function Write-OkHtml {
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
    [CmdletBinding()]
    [OutputType([Void])]

    Param (
        # HTTP Listener Response to write to
        [Parameter(Mandatory, Position = 0)]
        [Net.HttpListenerResponse]$Response,

        # Message to display in HTML response
        [Parameter(Mandatory, Position = 1)]
        [String]$Message
    ) # Param

    # Build HTML content
    [String]$Html      = "<html><body style='font-family:system-ui;'><h2>$Message</h2>You may close this tab.</body></html>" # Raw HTML
    [Byte[]]$HtmlBytes = $SCRIPT:Utf8.GetBytes($Html) # Encode to UTF8 bytes

    # Write response
    $Response.ContentLength64 = $HtmlBytes.Count # Set content length
    $Response.OutputStream.Write($HtmlBytes, 0, $HtmlBytes.Count) # Write content
    $Response.OutputStream.Close() # Close stream
} # Function Write-OkHtml
