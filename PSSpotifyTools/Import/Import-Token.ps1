Function Import-Token {
    <#
        .SYNOPSIS
        Imports a token from a file.

        .DESCRIPTION
        This function reads the token file, deserializes its content,
        and returns the token object.

        .PARAMETER Path
        The path to the file from which to import the token.

        .OUTPUTS
        [PSCustomObject] The imported token object.

        .EXAMPLE
        $Token = Import-Token
        Imports the token from the default token file.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    Param (
        # Filepath for token import
        [ValidateScript({$_.Exists})] # Ensure file exists
        [IO.FileInfo]$Path = $SCRIPT:TokenPath
    ) # Param

    # Check if file exists
    If (!$Path.Exists) {Throw [IO.FileNotFoundException]::New("Token file not found: $($Path.FullName)")}

    # Read and parse token
    [Byte[]]$TokenBytes  = [IO.File]::ReadAllBytes($Path.FullName) # Read file bytes
    [String]$TokenString = $SCRIPT:Utf8.GetString($TokenBytes) # Decode to string

    # Parse JSON
    [PSCustomObject]$Token = ConvertFrom-Json -InputObject $TokenString -Depth 100

    Return $Token
} # Function Import-Token
