Function New-CodeVerifier {
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
    [CmdletBinding()]
    [OutputType([String])]
 
    # Generate empty byte array
    [Byte[]]$RndBytes = [Byte[]]::New(64)

    # Fill byte array with cryptographically secure random bytes
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($RndBytes)

    # Convert filled byte array to base64url string
    [String]$Base64Url = ConvertTo-Base64Url $RndBytes

    Return $Base64Url
} # Function New-CodeVerifier
