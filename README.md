# naldodj-wsl-2FA
## Autenticação 2FA para Usuário Root no WSL

### Introdução

O Windows Subsystem for Linux (WSL) é uma ferramenta poderosa que permite aos desenvolvedores executar um ambiente Linux diretamente no Windows. No entanto, a segurança é uma preocupação importante, especialmente quando se trata de acessar o usuário root. Neste post, vamos mostrar como configurar a autenticação de dois fatores (2FA) para o usuário root ao acessar o WSL, garantindo uma camada adicional de segurança.

### Objetivo

Vamos configurar um script de login que valida a senha do root e usa autenticação 2FA baseada em Time-based One-Time Password (TOTP), usando ferramentas comuns como `openssl`, `oathtool`, e `perl`.

### Passo 1: Instalar as Ferramentas Necessárias

Primeiro, precisamos garantir que temos todas as ferramentas necessárias instaladas. Isso inclui `openssl`, `oathtool`, e `perl`.

```bash
sudo apt-get update
sudo apt-get install openssl oathtool perl
```
Para os scripts em Lua. Incluir `lua`, `lua-posix`

```bash
sudo apt-get install lua5.4
sudo apt-get install lua-posix
```

### Passo 2: Gerar e Armazenar a Chave Secreta

Criar o diretório `/root/2FA/`
```bash
makedir /root/2FA/
```

Criar o(s) diretório(s)
```bash
makedir /root/scripts/
makedir /root/scripts/sh/
makedir /root/scripts/lua/
makedir /root/scripts/ps/
makedir /root/scripts/hb/
makedir /root/scripts/perl/
```

Gerar uma chave secreta que será usada para gerar os códigos TOTP. Vamos armazenar essa chave em um arquivo seguro em `/root/2FA/`.

Crie um script chamado: [get2FAkey.sh](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/sh/get2FAkey.sh)

Ou, Crie um script chamado: [get2FAkey.lua](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/lua/get2FAkey.lua)

Ou, ainda, Crie um script chamado: [get2FAkey.ps1](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/ps/get2FAkey.ps1)

Ou: [get2FAkey.prg](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/get2FAkey.prg) : Dependente de LUA,PERL e PHYTON
Ou: [hb_get2FAkey.prg](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/hb_get2FAkey.prg) : Não Dependente de LUA,PERL ou PHYTON

Execute o script para gerar e armazenar a chave secreta:

```bash
chmod +x /root/scripts/sh/get2FAkey.sh
/root/scripts/sh/get2FAkey.sh
```

ou

```bash
chmod +x /root/scripts/lua/get2FAkey.lua
/root/scripts/lua/get2FAkey.lua
```

ou

```bash
chmod +x /root/scripts/ps/get2FAkey.lua
pwsh /root/scripts/ps/get2FAkey.ps1
```

ou, após compilar: [get2FAkey.prg](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/get2FAkey.prg)

```bash
chmod +x /root/scripts/hb/get2FAkey
/root/scripts/hb/get2FAkey
```

ou, após compilar: [hb_get2FAkey.prg](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/hb_get2FAkey.prg)

```bash
chmod +x /root/scripts/hb/hb_get2FAkey
/root/scripts/hb/hb_get2FAkey
```

### Passo 3: Configurar o Script de Login

Agora, vamos criar um script de login que valida a senha do root e solicita o código 2FA.

Crie um script chamado: [login.sh](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/sh/login.sh)
ou, Crie um script chamado: [login.lua](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/lua/login.lua)
ou, ainda, Crie um script chamado: [login.ps1](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/ps/login.ps1)
ou: [login.prg](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/login.prg)  : Dependente de LUA,PERL e PHYTON
ou: [hb_login.prg](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/hb_login.prg)  : Não dependente de LUA,PERL e PHYTON

### Passo 4: Configurar o Script para validar o Login

Vamos precisar de um scrit [check_password.pl](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/perl/check_password.pl) , em `Perl`, que será utilizado para validar a senha pelos demais scripts (exceto para  [hb_login.prg](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/hb_login.prg))

### Passo 5: Testar o Script de Login

1. **Defina permissões de execução para o script**:
    ```bash
    chmod +x /root/scripts/sh/login.sh
    ```
   ou
   ```bash
    chmod +x /root/scripts/lua/login.lua
   ```
   ou
   ```bash
    chmod +x /root/scripts/ps/login.ps1
   ```  
   ou, após compilar: [login.prg](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/login.prg)
   ```bash
    chmod +x /root/scripts/hb/login
   ```
   ou, após compilar: [hb_login.prg](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/hb_login.prg)
   ```bash
    chmod +x /root/scripts/hb/hb_login
   ```

3. **Execute o script de login**:
    ```bash
    /root/scripts/sh/login.sh
    ```
    ou
    ```bash
    /root/scripts/lua/login.lua
    ```
    ou
    ```bash
    pwsh /root/scripts/ps/login.ps1
    ```
    ou, opcionalmente e através do script [run_pslogin.sh](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/ps/run_pslogin.sh)
    ```bash
    /root/scripts/ps/run_pslogin.sh
    ```
    ou, após compilar: [login.prg](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/login.prg)
    ```bash
    /root/scripts/hb/login
    ```
    ou, após compilar: [hb_login.prg](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/hb_login.prg)
    ```bash
    /root/scripts/hb/hb_login
    ```

4. **Configure o aplicativo de 2FA** (como Microsoft Authenticator, Google Authenticator ou Authy) com a chave secreta armazenada em:
    `sh_2FAsecret_key.txt` ou
    `lua_2FAsecret_key.txt` ou
    `ps_2FAsecret_key.txt` ou
    `hb_2FAsecret_key.txt` ou

5. Configure o script para ser executado no login:

    Salve os scripts em suas respectivas pastas

    ```bash
    
    /root/scripts/sh/get2FAkey.sh
    /root/scripts/sh/login.sh
    
    /root/scripts/lua/get2FAkey.lua
    /root/scripts/lua/login.lua
    
    /root/scripts/perl/check_password.pl
    
    /root/scripts/ps/get2FAkey.ps1
    /root/scripts/ps/login.ps1
    /root/scripts/ps/run_pslogin.sh
    
    /root/scripts/hb/get2FAkey
    /root/scripts/hb/login

    /root/scripts/hb/hb_get2FAkey
    /root/scripts/hb/hb_login
    
    ```    

    Edite o arquivo .bashrc do root:
    ```bash
    nano /root/.bashrc
    ```
    Adicione a seguinte linha ao final do arquivo:
    ```bash
    #Scripts Login
    #/root/scripts/sh/login.sh
    #/root/scripts/lua/login.lua
    #/root/scripts/ps/run_pslogin.sh
    #/root/scripts/hb/login
    /$(whoami)/scripts/hb/hb_login -u=$(whoami)
    ```

    Teste a configuração:
    Feche o terminal WSL e abra novamente com o comando:
    ```bash
    wsl --user root
    ```

### Passo 6: Garanta que os scripts não possam ser acessados via \\wsl.localhost\ no windows

1. **Defina o usuário padrao
```bash
sudo editor /etc/wsl.conf
```
```bash
[user]
default=[NonRootUser]
```
2. **Alterar o dono do arquivo para o usuário root:
```bash
sudo chown root:root /etc/wsl.conf
```
3. **Alterar as permissões do arquivo para que apenas o dono (root) tenha acesso:
```bash
sudo chmod 600 /etc/wsl.conf
```
4. **Através do Powershell, Reincie a distro :
```bash
wsl --shutdown
```

### Conclusão

Com essas etapas, você configurou um sistema de autenticação robusto para o usuário root no WSL, utilizando uma senha e autenticação de dois fatores (2FA). Isso adiciona uma camada extra de segurança, protegendo contra acessos não autorizados. Lembre-se de armazenar a chave secreta em um local seguro e ajustar as permissões dos arquivos conforme necessário.

Essa configuração pode ser adaptada e aprimorada conforme suas necessidades específicas, mas serve como uma base sólida para garantir a segurança no uso do WSL.

---
### Extra: Harbour Version

Para instalar e usar o Harbour a partir do repositório GitHub e compilar seus scripts usando `hbmk2`, siga estes passos:

### Instalação do Harbour

1. **Clonar o Repositório**:

```sh
git clone https://github.com/harbour/core.git
cd core
```

2. **Instalar Dependências**:

```sh
sudo apt-get update
sudo apt-get install build-essential git libssl-dev libpcre3-dev libncurses5-dev libcurl4-openssl-dev
```

3. **Compilar e Instalar o Harbour**:

```sh
make
sudo make install
```

4. **Dependência Opcional**:

Se encontrar problemas relacionados ao `libpcre3`, instale:

```sh
sudo apt-get install libpcre3
```

### Verificação

Verifique se o Harbour foi instalado corretamente:

```sh
hbmk2 -version
```

### Compilar e Executar Seus Scripts

1. **Salvar os Scripts**: Salve `login.prg` e `get2FAkey.prg` nos arquivos correspondentes.

2. **Compilar os Scripts**:

[get2FAkey.hbp](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/get2FAkey.hbp)
[login.hbp](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/get2FAkey.hbp)

```sh
hbmk2 login.hbp
hbmk2 get2FAkey.hbp
```

ou

[hb_get2FAkey.hbp](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/hb_get2FAkey.hbp)
[hb_login.hbp](https://github.com/naldodj/naldodj-2FA-wsl/blob/main/src/hb/hb_get2FAkey.hbp)

```sh
hbmk2 hb_login.hbp
hbmk2 hb_get2FAkey.hbp
```

3. **Executar os Scripts**:

```sh
sudo ./login
sudo ./get2FAkey
```
ou
```sh
sudo ./hb_login
sudo ./hb_get2FAkey
```

### Dependências Adicionais

Certifique-se de ter o OpenSSL, Python e o OATH Toolkit instalados:

```sh
sudo apt-get install openssl python3 oathtool
```

### Resumo dos Scripts

1. **login.prg e hb_login.prg**:
   - Valida a senha do root.
   - Verifica o código 2FA.

2. **get2FAkey.prg e hb_get2FAkey.prg**:
   - Gera uma chave secreta para 2FA.
   - Armazena a chave em um arquivo protegido.

Seguindo estas etapas, você conseguirá configurar o Harbour a partir do código-fonte, compilar e executar seus scripts utilizando `hbmk2`.

---

## Referência(s):

[BlackTDN :: Como Forçar a Solicitação da Senha ao Acessar o WSL como Root](https://www.blacktdn.com.br/2024/06/blacktdn-como-forcar-solicitacao-da.html)

## GitHub:

[Autenticação 2FA para Usuário Root no WSL](https://github.com/naldodj/naldodj-2FA-wsl)
[Harbour](https://github.com/harbour/core)

---
