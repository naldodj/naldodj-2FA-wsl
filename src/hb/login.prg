#include "color.ch"
#include "inkey.ch"
#include "setcurs.ch"
#include "hbinkey.ch"

REQUEST HB_CODEPAGE_UTF8EX

function Main()

    local cSecretKeyFile as character:="/root/hb_2FAsecret_key.txt"

    hb_cdpSelect("UTF8EX")

    // Capturar SIGINT (Ctrl+C)
    SetKey(HB_K_CTRL_C,{||nil})
    SetKey(HB_K_ESC,{||nil})
    
    // Capturar SIGINT (Ctrl+Break)
    Set( _SET_CANCEL, .F. )

    CLS

    while (.T.)
        if (chkRootPWD())
            ? "Senha correta."
            if (chkRoot2FA(cSecretKeyFile))
                ? "Autenticação 2FA correta. Bem-vindo ao terminal."
                exit
            else
                ? "Código 2FA incorreto. Tente novamente."
            endif
        else
            ? "Senha incorreta. Tente novamente."
        endif
    end while

    return

static function chkRootPWD()

    local cCmd as character
    local cResult as character
    local cPassWord as character
    local cTmpPassWordFile as character:="/root/hb_tmp_chkRootPWD"
    local lChkRootPWD as logical

    cPassWord:=GetHiddenPassword()

    #pragma __cstream|cCmd:=%s
        perl "../perl/check_password.pl" "cPassWord" > cTmpPassWordFile 2>&1
    #pragma __endtext
    cCmd:=strTran(cCmd,"cPassWord",cPassWord)
    cCmd:=strTran(cCmd,"cTmpPassWordFile",cTmpPassWordFile)

    nResult:=hb_run(cCmd)
    if (hb_FileExists(cTmpPassWordFile))
        cResult:=hb_MemoRead(cTmpPassWordFile)
        hb_FileDelete(cTmpPassWordFile)
        cResult:=allTrim(strTran(cResult,hb_eol(),""))
    endif

    lChkRootPWD:=((nResult==0).and.(cResult==""))

    return(lChkRootPWD) as logical

static function chkRoot2FA(cSecretKeyFile as character)

    local cCmd as character
    local cSecretKey as character
    local cCodigo2FA as character
    local cTmpSecretKeyFile as character:="/root/hb_tmp_chkRoot2FA"

    local nResult as numeric

    local lChkRoot2FA as logical

    if (hb_FileExists(cSecretKeyFile))
        cSecretKey:=hb_MemoRead(cSecretKeyFile)
    else
        CLS
        cSecretKey:=Space(32)
        @ 0,0 SAY "Digite a chave secreta para 2FA: " GET cSecretKey
        READ
    endif
    cSecretKey:=allTrim(strTran(cSecretKey,hb_eol(),""))

    CLS
    cCodigo2FA:=Space(6)
    @ 0,0 SAY "Digite o código 2FA: " GET cCodigo2FA
    READ

    cCmd:="oathtool --totp -b "+cSecretKey+" > "+cTmpSecretKeyFile+" 2>&1"
    nResult:=hb_run(cCmd)
    if (hb_FileExists(cTmpSecretKeyFile))
        cSecretKey:=hb_MemoRead(cTmpSecretKeyFile)
        hb_FileDelete(cTmpSecretKeyFile)
        cSecretKey:=strTran(cSecretKey,hb_eol(),"")
    endif

    lChkRoot2FA:=((nResult==0).and.(cSecretKey==cCodigo2FA))

    return(lChkRoot2FA) as logical

static function GetHiddenPassword()

   local aGetList as array:=Array(0)
   local bKeyPaste as codeblock
   local cPassword as character:=Space(128)
   local nSavedRow as numeric

   QQOut(hb_eol())
   QQOut(hb_UTF8ToStr(hb_i18n_gettext("Enter password:"/*,_SELF_NAME_*/))+" ")

   nSavedRow:=Row()

   aAdd(aGetList,hb_Get():New(Row(),Col(),{|v|if(PCount()==0,cPassword,cPassword:=v)},"cPassword","@S"+hb_ntos(MaxCol()-Col()+1),hb_ColorIndex(SetColor(),CLR_STANDARD)+","+hb_ColorIndex(SetColor(),CLR_STANDARD)))
   aTail(aGetList):hideInput(.T.)
   aTail(aGetList):postBlock:={||!Empty(cPassword)}
   aTail(aGetList):display()

   SetCursor(if(ReadInsert(),SC_INSERT,SC_NORMAL))
   bKeyPaste:=SetKey(K_ALT_V,{||hb_gtInfo(HB_GTI_CLIPBOARDPASTE,.T.)})

   ReadModal(aGetList)

   /* Positions the cursor on the line previously saved */
   SetPos(nSavedRow,MaxCol()-1)
   SetKey(K_ALT_V,bKeyPaste)

   QQOut(hb_eol())

   return(AllTrim(cPassword)) as character