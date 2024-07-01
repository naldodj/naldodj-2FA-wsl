function Main {

    Clear-Host

    $SecretKeyFile = "/root/PS_2FAsecret_key.txt"
    
    #TODO: Tratar interrupção via <CTRL+C>
    while ($true) {
        if (chkRootPWD) {
            Write-Host "Senha correta."
            if (chkRoot2FA $SecretKeyFile) {
                Write-Host "Autenticação 2FA correta. Bem-vindo ao terminal."
                break
            } else {
                Write-Host "Código 2FA incorreto. Tente novamente."
            }
        } else {
            Write-Host "Senha incorreta. Tente novamente."
        }
    }
}

function chkRootPWD {
    $chkRootPWD = $false
    $PassWord = GetHiddenPassword
    $TmpPassWordFile = "/root/PS_tmp_chkRootPWD"

    # Verifica a senha utilizando um script em Perl
    perl "../perl/check_password.pl" "$PassWord" > $TmpPassWordFile 2>&1

    # Verifica o código de saída do último comando executado
    $chkRootPWD = ($LASTEXITCODE -eq 0)
    if ($chkRootPWD) {
        # Verifica se o arquivo temporário existe
        $chkRootPWD = (Test-Path $TmpPassWordFile)
        if ($chkRootPWD) {
            # Lê o conteúdo do arquivo temporário
            $Result = Get-Content $TmpPassWordFile
            # Remove o arquivo temporário
            Remove-Item $TmpPassWordFile
            # Verifica se a string resultante está vazia
            $chkRootPWD = ([string]::IsNullOrEmpty($Result))
        }
        # Retorna verdadeiro se o resultado estiver vazio (senha correta)
        return ($chkRootPWD)
    } else {
        # Retorna falso se o código de saída for diferente de 0 (erro na execução do script Perl)
        return $chkRootPWD
    }
}

function chkRoot2FA {
    param (
        [string]$SecretKeyFile
    )

    $TmpSecretKeyFile = "/root/PS_tmp_chkRoot2FA"

    if (Test-Path $SecretKeyFile) {
        $SecretKey = Get-Content $SecretKeyFile
    } else {
        Clear-Host
        $SecretKey = Read-Host "Digite a chave secreta para 2FA"
    }
    $SecretKey = $SecretKey -replace "`n", ""

    Clear-Host
    $Codigo2FA = Read-Host "Digite o código 2FA"

    $Cmd = "oathtool --totp -b $SecretKey > $TmpSecretKeyFile 2>&1"
    Invoke-Expression $Cmd

    if (Test-Path $TmpSecretKeyFile) {
        $SecretKey = Get-Content $TmpSecretKeyFile
        Remove-Item $TmpSecretKeyFile
        $SecretKey = $SecretKey -replace "`n", ""
    }

    return ($SecretKey -and $SecretKey -eq $Codigo2FA)
}

function GetHiddenPassword {
    $Password = Read-Host "Enter password" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

Main