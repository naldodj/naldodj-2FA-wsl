REQUEST HB_CODEPAGE_UTF8EX

#include "hbver.ch"

#pragma -w3

procedure Main(...)

    local aArgs as array:=hb_AParams()

    local cParam as character
    local cArgName as character
    local cSecretKey as character
    local cUserName as character:=hb_UserName() 
#if defined( HB_OS_WIN )
    local cSecretKeyPath as character:="c:\root\2FA\"
#else
    local cSecretKeyPath as character:="/"+cUserName+"/2FA/"
#endif    
    local cSecretKeyFile as character
    
    local idx as numeric
    local nSizeSecretKey as numeric
    
    local lBase64 as logical

    hb_cdpSelect("UTF8EX")

    if ("CYGWIN_NT"$OS())
        cSecretKeyPath:="c:\"+cUserName+"\2FA\"
    endif

    cSecretKeyFile:=hb_FNameMerge(cSecretKeyPath,"hb_2FAsecret_key",".txt")

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
                    case (cArgName=="-s")
                        nSizeSecretKey:=val(cParam)
                    case (cArgName=="-base64-")
                        lBase64:=.F.
                    case (cArgName=="-u").or.(cArgName=="-user")
                        cSecretKeyPath:=strTran(cSecretKeyPath,cUserName,cParam)
                        cUserName:=cParam
                    otherwise
                        ShowHelp("Unrecognized option:"+cArgName+iif(Len(cParam)>0,"="+cParam,""))
                        break
                endcase
            endif
        next each

        hb_default(@nSizeSecretKey,20)
        hb_default(@lBase64,.T.)

        if (!hb_DirExists(cSecretKeyPath))
            hb_DirCreate(cSecretKeyPath)
        endif

        if (hb_FileExists(cSecretKeyFile))
            ? "A chave secreta já existe em ",cSecretKeyFile
        else
            cSecretKey:=Generate2FAKey(nSizeSecretKey,lBase64)
            if ((!Empty(cSecretKey)).and.(hb_MemoWrit(cSecretKeyFile,cSecretKey)).and.(hb_FileExists(cSecretKeyFile)))
                #if !defined( HB_OS_WIN )
                    hb_Run("chmod +600 "+cSecretKeyFile)
                #endif
                ? "Chave secreta gerada e armazenada em ",cSecretKeyFile
            else
                ? "Problema na geração do arquivo ",cSecretKeyFile
            endif
        endif
        
    end sequence

    return

static function Generate2FAKey(nSizeSecretKey,lBase64)

    local cSecretKey as character
    local cBase32Secret as character
    local ohb_Base32 as object:=hb_Base32():New()

    // Gerar nSizeSecretKey bytes aleatórios
    cSecretKey:=hb_randStr(nSizeSecretKey)
    
    // Converter em Base 64
    if (lBase64)
        cSecretKey:=hb_base64Encode(cSecretKey,.F.)
    endif
    
    // Converter a chave secreta para Base32
    cBase32Secret:=ohb_Base32:Encode_C(cSecretKey)

    return(cBase32Secret) as character

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
            ,"-s=<digits>        Specify the number of digits in the key code";
            ,"-u=<user name>     Specify the user name or";
            ,"-user=<user name>  Specify the user name";
            ,"-base64-           When this option is specified, the random key generated will not be encoded in base64 before being converted to base32";
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