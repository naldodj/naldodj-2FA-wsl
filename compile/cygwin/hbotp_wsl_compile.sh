#!/bin/bash

# Definir a variável para o caminho do hbmk2
HBMK2=~/naldodj-hb/bin/cygwin/gcc/hbmk2.exe

# Definir a variável para o caminho repositório
HB_OTPPATH=/cygdrive/c/GitHub/naldodj-2FA-wsl/src/hb/hbp/

# Definir a variável para dos binários gerados
HB_OTPPATHBIN=/root/scripts/hb/

# Mudar para o diretório de origem
cd $HB_OTPPATH

# Compilar os arquivos .hbp usando hbmk2
$HBMK2 get2FAkey.hbp
$HBMK2 hb_get2FAkey.hbp
$HBMK2 hb_login.hbp
$HBMK2 login.hbp

# Mudar para o diretório binário
cd $HB_OTPPATHBIN

# Compactar os arquivos .exe usando upx
upx get2FAkey.exe
upx hb_get2FAkey.exe
upx hb_login.exe
upx login.exe

# Copiar os arquivos para a pasta bin do projeto (descomente se necessário)
cp get2FAkey.exe /cygdrive/c/GitHub/naldodj-2FA-wsl/bin/hb/
cp hb_get2FAkey.exe /cygdrive/c/GitHub/naldodj-2FA-wsl/bin/hb/
cp hb_login.exe /cygdrive/c/GitHub/naldodj-2FA-wsl/bin/hb/
cp login.exe /cygdrive/c/GitHub/naldodj-2FA-wsl/bin/hb/

# Voltar para o diretório inicial (descomente se necessário)
# cd /cygdrive/c/GitHub/naldodj-2FA-wsl/
