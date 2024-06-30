REQUEST HB_CODEPAGE_UTF8EX

function Main()

    local cSecretKey as character
    local cSecretKeyFile as character:="/root/hb_2FAsecret_key.txt"

    hb_cdpSelect("UTF8EX")

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

    local cCmd as character
    local cSecretKey as character
    local cTmpSecretKey as character
    local cBase32Secret as character

    // Gerar 20 bytes aleatórios usando OpenSSL
    cTmpSecretKey:="/root/hb_2FA_tmp_secret_key"
    hb_run("openssl rand -base64 20 > "+cTmpSecretKey)

    // Verifica se o arquivo foi gerado com a chave
    if (hb_FileExists(cTmpSecretKey))

        cSecretKey:=hb_memoread(cTmpSecretKey)
        hb_FileDelete(cTmpSecretKey)

        cSecretKey:=strTran(cSecretKey,hb_eol(),"")

        // Converter a chave secreta para Base32 usando Python
        #pragma __cstream | cCmd:=%s
            python3 -c \"import base64; print(base64.b32encode(base64.b64decode('cSecretKey')).decode('utf-8'))\" > cTmpSecretKey
        #pragma __endtext

        cCmd:=strTran(cCmd,"cSecretKey",cSecretKey)
        cCmd:=strTran(cCmd,"cTmpSecretKey",cTmpSecretKey)

        // Converter a chave secreta para Base32 usando Python
        hb_run(cCmd)
        if (hb_FileExists(cTmpSecretKey))
            cBase32Secret:=hb_MemoRead(cTmpSecretKey)
            hb_FileDelete(cTmpSecretKey)
        else
            cBase32Secret:=""
        endif

    else

        cBase32Secret:=""

    endif

    // Remover quebras de linha
    cBase32Secret:=strTran(cBase32Secret,hb_eol(),"")

    return(cBase32Secret) as character
