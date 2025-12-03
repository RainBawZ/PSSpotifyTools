Function Export-Token {
    <#
        .SYNOPSIS
        Exports the specified token to a file.

        .DESCRIPTION
        This function serializes the given token object and writes it to a file
        in the specified token directory.

        .PARAMETER Token
        The token object to export.

        .PARAMETER Path
        Export output path.

        .OUTPUTS
        [Void]

        .EXAMPLE
        Export-Token -Token $Token
        Exports the specified token to a file.
    #>
    [CmdletBinding()]
    [OutputType([Void])]

    Param (
        # Token to export
        [Parameter(Mandatory, Position = 0)]
        [PSCustomObject]$Token,

        # File to store exported token
        [Parameter(Position = 1)]
        [ValidateScript({$_.Directory.Exists})] # Ensure directory exists
        [IO.FileInfo]$Path = $SCRIPT:TokenPath
    ) # Param

    # Check if directory exists
    If (!$Path.Directory.Exists) {Throw [IO.DirectoryNotFoundException]::New("Token directory not found: $($Path.Directory.FullName)")}

    # Serialize token to JSON
    [String]$Json = ConvertTo-Json -InputObject $Token -Depth 100 -Compress

    # Write to file
    [IO.File]::WriteAllText($Path, $Json, $SCRIPT:Utf8)
} # Function Export-Token
