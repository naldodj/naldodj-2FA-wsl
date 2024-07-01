# Caminho para o arquivo da chave secreta
$SECRET_KEY_FILE="/root/PS_2FAsecret_key.txt"

function Generate2FAKey {

    # Gerar 20 bytes aleatórios usando OpenSSL
    $cTmpSecretKey="/root/PS_2FA_tmp_secret_key"
    $opensslCmd="openssl rand -base64 20 > $cTmpSecretKey"
    Invoke-Expression $opensslCmd

    # Verifica se o arquivo foi gerado com a chave
    if (Test-Path $cTmpSecretKey) {
        $cSecretKey=Get-Content $cTmpSecretKey
        Remove-Item $cTmpSecretKey

        $cSecretKey=$cSecretKey -replace "`n", ""

        # Converter a chave secreta para Base32 usando Python
        $pythonCmd="python3 -c `"import base64; print(base64.b32encode(base64.b64decode('$cSecretKey')).decode('utf-8'))`" > $cTmpSecretKey"
        Invoke-Expression $pythonCmd

        if (Test-Path $cTmpSecretKey) {
            $cBase32Secret=Get-Content $cTmpSecretKey
            Remove-Item $cTmpSecretKey
        } else {
            $cBase32Secret=""
        }
    } else {
        $cBase32Secret=""
    }
    
    return $cBase32Secret
}

if (Test-Path $SECRET_KEY_FILE) {
    Write-Host "A chave secreta já existe em $SECRET_KEY_FILE."
} else {
    $base32Secret=Generate2FAKey
    Set-Content -Path $SECRET_KEY_FILE -Value $base32Secret
    chmod 600 $SECRET_KEY_FILE
    Write-Host "Chave secreta gerada e armazenada em $SECRET_KEY_FILE."
}