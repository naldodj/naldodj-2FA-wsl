#include "hbver.ch"
#include "color.ch"
#include "inkey.ch"
#include "setcurs.ch"
#include "hbinkey.ch"
#include "hbgtinfo.ch"

#pragma -w3

REQUEST HB_CODEPAGE_UTF8EX

memvar GETLIST

procedure Main(...)

    local aArgs as array:=hb_AParams()

    local cParam as character
    local cArgName as character
    local cUserName:=hb_UserName() as character
#if defined( HB_OS_WIN )
    local cSecretKeyPath as character:="c:\"+cUserName+"\2FA\"
#else
    local cSecretKeyPath as character:="/"+cUserName+"/2FA/"
#endif
    local cSecretKeyFile as character

    local idx as numeric
    local nSizeOTPCode as numeric
    local nSizeSecretKey as numeric

    hb_cdpSelect("UTF8EX")

    begin sequence

        if (;
                (!Empty(aArgs));
                .and.;
                (;
                    Lower(aArgs[1])=="-h";
                    .or.;
                    Lower(aArgs[1])=="--help";
                );
        )
            ShowHelp(nil,aArgs)
            break
        endif

        for each cParam in aArgs
            if (!Empty(cParam))
                if ((idx:=At("=",cParam))==0)
                    cArgName:=Lower(cParam)
                    cParam:=""
                else
                    cArgName:=Left(cParam,idx-1)
                    cParam:=SubStr(cParam,idx+1)
                endif
                do case
                    case (cArgName=="-sotp")
                        nSizeOTPCode:=val(cParam)
                    case (cArgName=="-skey")
                        nSizeSecretKey:=val(cParam)
                    case (cArgName=="-u").or.(cArgName=="-user")
                        cSecretKeyPath:=strTran(cSecretKeyPath,cUserName,cParam)
                        cUserName:=cParam
                    otherwise
                        ShowHelp("Unrecognized option:"+cArgName+iif(Len(cParam)>0,"="+cParam,""))
                        break
                endcase
            endif
        next each

        hb_default(@nSizeOTPCode,6)
        hb_default(@nSizeSecretKey,20)

        if ("CYGWIN_NT"$OS())
            cSecretKeyPath:="c:\"+cUserName+"\2FA\"
        endif

        cSecretKeyFile:=hb_FNameMerge(cSecretKeyPath,"hb_2FAsecret_key",".txt")

        // Capturar SIGINT (Ctrl+C)
        SetKey(HB_K_CTRL_C,{||nil})
        SetKey(HB_K_ESC,{||nil})

        // Capturar SIGINT (Ctrl+Break)
        Set(_SET_CANCEL,.F.)

        CLS

        while (.T.)
            if (chkUserPWD(cUserName))
                ? "Senha correta."
                if (ChkUser2FA(cSecretKeyFile,nSizeSecretKey,nSizeOTPCode))
                    ? "Autenticação 2FA correta. Bem-vindo ao terminal."
                    exit
                else
                    ? "Código 2FA incorreto. Tente novamente."
                endif
            else
                ? "Senha incorreta. Tente novamente."
            endif
        end while

    end sequence

    return

static function chkUserPWD(cUserName as character)

    local cPassWord as character
    local lchkUserPWD as logical

    #if !defined( __PLATFORM__WINDOWS )
        #if !defined( __PLATFORM__CYGWIN )
            local hUserInfo as hash
        #endif
    #endif

    cPassWord:=GetHiddenPassword()

    #if !defined( __PLATFORM__WINDOWS )
        #if !defined( __PLATFORM__CYGWIN )
            hUserInfo:=hb_UserInfo(cUserName)
            lchkUserPWD:=(HB_CRYPT(cPassword,hUserInfo["passwd"])==hUserInfo["passwd"])
        #else
            lchkUserPWD:=(HB_WIN_VALIDATEPASSWORD(cUserName,".",cPassWord))
        #endif
    #else
        lchkUserPWD:=(HB_WIN_VALIDATEPASSWORD(cUserName,".",cPassWord))
    #endif

    return(lchkUserPWD) as logical

static function ChkUser2FA(cSecretKeyFile as character,nSizeSecretKey as numeric,nSizeOTPCode as numeric)

    local cOTPKey as character
    local cSecretKey as character
    local cCodigo2FA as character

    local lChkUser2FA as logical

    local oHB_OTP as object

    private GETLIST as array:=Array(0)

    if (hb_FileExists(cSecretKeyFile))
        cSecretKey:=hb_MemoRead(cSecretKeyFile)
    else
        CLS
        cSecretKey:=Space(nSizeSecretKey)
        @ 0,0 SAY "Digite a chave secreta para 2FA: " GET cSecretKey
        READ
    endif
    cSecretKey:=allTrim(strTran(cSecretKey,hb_eol(),""))

    aSize(GETLIST,0)

    CLS
    cCodigo2FA:=Space(nSizeOTPCode)
    @ 0,0 SAY "Digite o código 2FA: " GET cCodigo2FA
    READ

    oHB_OTP:=hb_OTP():New()
    cOTPKey:=oHB_OTP:OTP_TOTP(cSecretKey,nSizeOTPCode,30,"SHA1")

    lChkUser2FA:=(cOTPKey==cCodigo2FA)
    if ((lChkUser2FA).and.(!hb_FileExists(cSecretKeyFile)))
        hb_MemoWrit(cSecretKeyFile,cSecretKey)
    endif

    return(lChkUser2FA) as logical

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

static procedure ShowSubHelp(xLine as anytype,/*@*/nMode as numeric,nIndent as numeric,n as numeric)

   DO CASE
      CASE xLine == NIL
      CASE HB_ISNUMERIC( xLine )
         nMode := xLine
      CASE HB_ISEVALITEM( xLine )
         Eval( xLine )
      CASE HB_ISARRAY( xLine )
         IF nMode == 2
            OutStd( Space( nIndent ) + Space( 2 ) )
         ENDIF
         AEval( xLine, {| x, n | ShowSubHelp( x, @nMode, nIndent + 2, n ) } )
         IF nMode == 2
            OutStd( hb_eol() )
         ENDIF
      OTHERWISE
         DO CASE
            CASE nMode == 1 ; OutStd( Space( nIndent ) + xLine + hb_eol() )
            CASE nMode == 2 ; OutStd( iif( n > 1, ", ", "" ) + xLine )
            OTHERWISE       ; OutStd( "(" + hb_ntos( nMode ) + ") " + xLine + hb_eol() )
         ENDCASE
   ENDCASE

   RETURN

static function HBRawVersion()
   return(;
       hb_StrFormat( "%d.%d.%d%s (%s) (%s)";
      ,hb_Version(HB_VERSION_MAJOR);
      ,hb_Version(HB_VERSION_MINOR);
      ,hb_Version(HB_VERSION_RELEASE);
      ,hb_Version(HB_VERSION_STATUS);
      ,hb_Version(HB_VERSION_ID);
      ,"20"+Transform(hb_Version(HB_VERSION_REVISION),"99-99-99 99:99"));
   ) as character

static procedure ShowHelp(cExtraMessage as character,aArgs as array)

   local aHelp as array
   local nMode as numeric:=1

   if (Empty(aArgs).or.(Len(aArgs)<=1).or.(Empty(aArgs[1])))
      aHelp:={;
         cExtraMessage;
         ,"HB_GET2FAKEY ("+ExeName()+") "+HBRawVersion();
         ,"Copyright (c) 2024-"+hb_NToS(Year(Date()))+", "+hb_Version(HB_VERSION_URL_BASE);
         ,"";
         ,"Syntax:";
         ,"";
         ,{ExeName()+" [options]"};
         ,"";
         ,"Options:";
         ,{;
             "-h                 Show this help screen or";
            ,"--help             Show this help screen";
            ,"-sotp=<digits>     Specify the number of digits in the otp code";
            ,"-skey=<digits>     Specify the number of digits in the key code";
            ,"-u=<user name>     Specify the user name or";
            ,"-user=<user name>  Specify the user name";
         };
         ,"";
      }
   else
      ShowHelp("Unrecognized help option")
      return
   endif

   /* using hbmk2 style */
   aEval(aHelp,{|x|ShowSubHelp(x,@nMode,0)})

   return

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
