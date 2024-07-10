REQUEST HB_CODEPAGE_UTF8EX

#pragma -w3

procedure Main()

    local cSecretKey as character
    local cSecretKeyPath as character:="/root/2FA/"
    local cSecretKeyFile as character:=hb_FNameMerge(cSecretKeyPath,"hb_2FAsecret_key",".txt")

    hb_cdpSelect("UTF8EX")

    if (!hb_DirExists(cSecretKeyPath))
        hb_DirCreate(cSecretKeyPath)
    endif

    if (hb_FileExists(cSecretKeyFile))
        ? "A chave secreta já existe em ",cSecretKeyFile
    else
        cSecretKey:=Generate2FAKey()
        if ((!Empty(cSecretKey)).and.(hb_MemoWrit(cSecretKeyFile,cSecretKey)).and.(hb_FileExists(cSecretKeyFile)))
            hb_Run("chmod +600 "+cSecretKeyFile)
            ? "Chave secreta gerada e armazenada em ",cSecretKeyFile
        else
            ? "Problema na geração do arquivo ",cSecretKeyFile
        endif
    endif

    return

static function Generate2FAKey()

    local cSecretKey as character
    local cTmpSecretKey as character
    local cBase32Secret as character
    local ohb_Base32 as object:=hb_Base32():New()

    // Gerar 20 bytes aleatórios usando OpenSSL
    cTmpSecretKey:="/root/hb_2FA_tmp_secret_key"
    hb_run("openssl rand -base64 20 > "+cTmpSecretKey)

    // Verifica se o arquivo foi gerado com a chave
    if (hb_FileExists(cTmpSecretKey))

        cSecretKey:=hb_memoread(cTmpSecretKey)
        hb_FileDelete(cTmpSecretKey)

        cSecretKey:=strTran(cSecretKey,hb_eol(),"")

        // Converter a chave secreta para Base32
        cBase32Secret:=ohb_Base32:Encode_C(cSecretKey)

    else

        cBase32Secret:=""

    endif

    return(cBase32Secret) as character
