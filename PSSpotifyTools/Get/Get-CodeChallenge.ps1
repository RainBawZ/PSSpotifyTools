Function Get-CodeChallenge {
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
    [CmdletBinding()]
    [OutputType([String])]

    Param (
        # CodeVerifier parameter
        [Parameter(Mandatory)]
        [String]$CodeVerifier
    ) # Param

    # Compute SHA-256 hash
    [Byte[]]$CodeVerifierBytes = $SCRIPT:Ascii.GetBytes($CodeVerifier) # ASCII encoding
    [Byte[]]$HashBytes         = [Security.Cryptography.SHA256]::Create().ComputeHash($CodeVerifierBytes) # SHA-256 hash
    [String]$Base64UrlHash     = ConvertTo-Base64Url $HashBytes # Base64url encode

    Return $Base64UrlHash
} # Function Get-CodeChallenge
