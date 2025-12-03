Function ConvertTo-Base64Url {
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
    [CmdletBinding()]
    [OutputType([String])]

    Param (
        # Bytes to convert
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Byte[]]$Bytes
    ) # Param

    # Convert byte array to base64url string
    [String]$Base64Url = [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_') # Base64url encoding

    Return $Base64Url
} # Function ConvertTo-Base64Url
