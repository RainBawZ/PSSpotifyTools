Function Stop-LocalListener {
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
    [CmdletBinding()]
    [OutputType([Void])]

    Param (
        # HTTP Listener to stop
        [Parameter(Mandatory)]
        [Net.HttpListener]$Listener
    ) # Param

    # Stop and close listener
    $Listener.Stop()
    $Listener.Close()
} # Function Stop-LocalListener
