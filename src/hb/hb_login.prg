#include "color.ch"
#include "inkey.ch"
#include "setcurs.ch"
#include "hbinkey.ch"
#include "hbgtinfo.ch"

#pragma -w3

REQUEST HB_CODEPAGE_UTF8EX

memvar GETLIST

procedure Main()

    local cSecretKeyPath as character:="/root/2FA/"
    local cSecretKeyFile as character:=hb_FNameMerge(cSecretKeyPath,"hb_2FAsecret_key",".txt")

    hb_cdpSelect("UTF8EX")

    // Capturar SIGINT (Ctrl+C)
    SetKey(HB_K_CTRL_C,{||nil})
    SetKey(HB_K_ESC,{||nil})

    // Capturar SIGINT (Ctrl+Break)
    Set(_SET_CANCEL,.F.)

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

    local cPassWord as character
    local lChkRootPWD as logical
    
    #if !defined( __PLATFORM__WINDOWS )
        #if !defined( __PLATFORM__CYGWIN )
            local hUserInfo as hash
        #endif
    #endif

    cPassWord:=GetHiddenPassword()

    #if !defined( __PLATFORM__WINDOWS )
        #if !defined( __PLATFORM__CYGWIN )
            hUserInfo:=hb_UserInfo("root")
            lChkRootPWD:=(HB_CRYPT(cPassword,hUserInfo["passwd"])==hUserInfo["passwd"])
        #else
            lChkRootPWD:=(HB_WIN_VALIDATEPASSWORD(hb_UserName(),".",cPassWord))
        #endif
    #else
        lChkRootPWD:=(HB_WIN_VALIDATEPASSWORD(hb_UserName(),".",cPassWord))
    #endif

    return(lChkRootPWD) as logical

static function chkRoot2FA(cSecretKeyFile as character)

    local cSecretKey as character
    local cCodigo2FA as character

    local lChkRoot2FA as logical

    local oHB_OTP as object

    private GETLIST as array:=Array(0)

    if (hb_FileExists(cSecretKeyFile))
        cSecretKey:=hb_MemoRead(cSecretKeyFile)
    else
        CLS
        cSecretKey:=Space(32)
        @ 0,0 SAY "Digite a chave secreta para 2FA: " GET cSecretKey
        READ
    endif
    cSecretKey:=allTrim(strTran(cSecretKey,hb_eol(),""))

    aSize(GETLIST,0)

    CLS
    cCodigo2FA:=Space(6)
    @ 0,0 SAY "Digite o código 2FA: " GET cCodigo2FA
    READ

    oHB_OTP:=hb_OTP():New()
    cSecretKey:=oHB_OTP:OTP_TOTP(cSecretKey,6,30,"SHA1")

    lChkRoot2FA:=(cSecretKey==cCodigo2FA)
    if ((lChkRoot2FA).and.(!hb_FileExists(cSecretKeyFile)))
        hb_MemoWrit(cSecretKeyFile,cSecretKey)
    endif

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

#pragma BEGINDUMP

    #include "hbapi.h"
    #include "hbapierr.h"
    #include "hbapiitm.h"
    #include "hbapicls.h"
    #include "hbapifs.h"

    #if defined(__CYGWIN__) || defined(__PLATFORM__WINDOWS)
        #include <windows.h>
        #include <crypt.h>
        #include <pwd.h>
        #include <sys/types.h>
        #include <unistd.h>
    #else
        #include <crypt.h>
        #if defined(HB_OS_OS2) && defined(__GNUC__)
            #include <pwd.h>
            #include <sys/types.h>
        #elif defined(HB_OS_UNIX) && !defined(HB_OS_VXWORKS) && !defined(__WATCOMC__)
            #include <pwd.h>
            #include <sys/types.h>
            #include <unistd.h>
            #include <shadow.h>
        #endif
    #endif

    #if !defined( __PLATFORM__WINDOWS ) && !defined( __CYGWIN__ )

        HB_FUNC_STATIC(HB_USERINFO)
        {
            const char *username = hb_parc(1);
            if (username)
            {
                struct passwd *pwd = getpwnam(username);
                if (pwd)
                {
                    PHB_ITEM pHash = hb_hashNew(NULL);

                    PHB_ITEM pItemKey;
                    PHB_ITEM pItemValue;

                    pItemKey = hb_itemPutC(NULL, "name");
                    pItemValue = hb_itemPutC(NULL, pwd->pw_name);
                    hb_hashAdd(pHash, pItemKey, pItemValue);
                    hb_itemRelease(pItemKey);
                    hb_itemRelease(pItemValue);

                    pItemKey = hb_itemPutC(NULL, "passwd");
                    #if defined(HB_OS_UNIX) && !defined(HB_OS_VXWORKS) && !defined(__WATCOMC__) && !defined(__CYGWIN__)
                        struct spwd *spwd = getspnam(username);
                        if (spwd)
                        {
                            pItemValue = hb_itemPutC(NULL, spwd->sp_pwdp);
                        }
                        else
                        {
                            pItemValue = hb_itemPutC(NULL, pwd->pw_passwd);
                        }
                    #else
                        pItemValue = hb_itemPutC(NULL, "x");
                    #endif

                    hb_hashAdd(pHash, pItemKey, pItemValue);
                    hb_itemRelease(pItemKey);
                    hb_itemRelease(pItemValue);

                    pItemKey = hb_itemPutC(NULL, "uid");
                    pItemValue = hb_itemPutNI(NULL, pwd->pw_uid);
                    hb_hashAdd(pHash, pItemKey, pItemValue);
                    hb_itemRelease(pItemKey);
                    hb_itemRelease(pItemValue);

                    pItemKey = hb_itemPutC(NULL, "gid");
                    pItemValue = hb_itemPutNI(NULL, pwd->pw_gid);
                    hb_hashAdd(pHash, pItemKey, pItemValue);
                    hb_itemRelease(pItemKey);
                    hb_itemRelease(pItemValue);

                    pItemKey = hb_itemPutC(NULL, "gecos");
                    pItemValue = hb_itemPutC(NULL, pwd->pw_gecos);
                    hb_hashAdd(pHash, pItemKey, pItemValue);
                    hb_itemRelease(pItemKey);
                    hb_itemRelease(pItemValue);

                    pItemKey = hb_itemPutC(NULL, "dir");
                    pItemValue = hb_itemPutC(NULL, pwd->pw_dir);
                    hb_hashAdd(pHash, pItemKey, pItemValue);
                    hb_itemRelease(pItemKey);
                    hb_itemRelease(pItemValue);

                    hb_hashAdd(pHash, hb_itemPutC(NULL, "shell"), hb_itemPutC(NULL, pwd->pw_shell));
                    hb_itemRelease(pItemKey);
                    hb_itemRelease(pItemValue);

                    hb_itemReturnRelease(pHash);

                    return;
                }
            }
            hb_retc_null();
        }
        
        HB_FUNC_STATIC(HB_CRYPT)
        {
            const char *password = hb_parc(1);
            const char *salt = hb_parc(2);

            if (password && salt)
            {
                char *encrypted = crypt(password, salt);
                if (encrypted)
                    hb_retc(encrypted);
                else
                    hb_retc_null();
            }
            else
            {
                hb_retc_null();
            }
        }
        

    #else

        HB_FUNC_STATIC(HB_WIN_VALIDATEPASSWORD)
        {
            const char *username = hb_parc(1);
            const char *domain = hb_parc(2);
            const char *password = hb_parc(3);

            HANDLE hToken;
            BOOL result = LogonUserA(
                username,
                domain,
                password,
                LOGON32_LOGON_INTERACTIVE,
                LOGON32_PROVIDER_DEFAULT,
                &hToken
            );

            if (result)
            {
                CloseHandle(hToken);
            }

            hb_retl(result);
        }

    #endif

#pragma ENDDUMP
