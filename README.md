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

Vamos gerar uma chave secreta que será usada para gerar os códigos TOTP. Vamos armazenar essa chave em um arquivo seguro.

Crie um script chamado `get2FAkey.sh`:

```bash
#!/bin/bash

# Nome do arquivo onde a chave secreta será armazenada
SECRET_KEY_FILE="/root/2FAsecret_key.txt"

# Função para gerar uma chave secreta aleatória em Base32
get2FAkey() {
    # Gera 20 bytes aleatórios (160 bits)
    local secret_key=$(openssl rand -base64 20)

    # Converte a chave secreta para Base32 usando Python
    local base32_secret=$(python3 -c "import base64, base64; print(base64.b32encode(base64.b64decode('$secret_key')).decode('utf-8'))")

    echo "$base32_secret"
}

# Verifica se o arquivo da chave secreta já existe
if [ -f "$SECRET_KEY_FILE" ]; then
    echo "A chave secreta já existe em $SECRET_KEY_FILE."
else
    # Gera uma nova chave secreta
    base32_secret=$(get2FAkey)

    # Armazena a chave secreta no arquivo
    echo "$base32_secret" &gt; "$SECRET_KEY_FILE"

    # Define permissões restritivas para o arquivo
    chmod 600 "$SECRET_KEY_FILE"

    echo "Chave secreta gerada e armazenada em $SECRET_KEY_FILE."
fi
```

Ou, Crie um script chamado `get2FAkey.lua`:

```lua
#!/usr/bin/lua

local SECRET_KEY_FILE = "/root/2FAsecret_key.txt"

-- Função para gerar uma chave secreta aleatória em Base32
function get2FAkey()
    -- Gera 20 bytes aleatórios (160 bits) usando openssl
    local handle = io.popen("openssl rand -base64 20")
    local secret_key = handle:read("*a"):gsub("\n", "")
    handle:close()

    -- Converte a chave secreta para Base32 usando Python
    local cmd = string.format([[python3 -c "import base64; print(base64.b32encode(base64.b64decode('%s')).decode('utf-8'))"]], secret_key)
    handle = io.popen(cmd)
    local base32_secret = handle:read("*a"):gsub("\n", "")
    handle:close()

    return base32_secret
end

-- Verifica se o arquivo da chave secreta já existe
local file = io.open(SECRET_KEY_FILE, "r")
if file then
    print(string.format("A chave secreta já existe em %s.", SECRET_KEY_FILE))
    file:close()
else
    -- Gera uma nova chave secreta
    local base32_secret = get2FAkey()

    -- Armazena a chave secreta no arquivo
    file = io.open(SECRET_KEY_FILE, "w")
    file:write(base32_secret)
    file:close()

    -- Define permissões restritivas para o arquivo
    os.execute(string.format("chmod 600 %s", SECRET_KEY_FILE))

    print(string.format("Chave secreta gerada e armazenada em %s.", SECRET_KEY_FILE))
end
```

Execute o script para gerar e armazenar a chave secreta:

```bash
chmod +x get2FAkey.sh
./get2FAkey.sh
```
ou

```bash
chmod +x get2FAkey.lua
./get2FAkey.lua
```

### Passo 3: Configurar o Script de Login

Agora, vamos criar um script de login que valida a senha do root e solicita o código 2FA.

Crie um script chamado `login.sh`:

```bash
#!/bin/bash

# Caminho para o arquivo da chave secreta
SECRET_KEY_FILE="/root/2FAsecret_key.txt"

# Função para validar a senha do root usando Perl
chkRootPWD() {
    # Solicita a senha de forma segura e armazena em uma variável
    read -s -p "Digite a senha do root: " senha

    # Executa a validação da senha usando Perl
    perl -e '
        use strict;
        use warnings;
        my @pwent = getpwnam("root");
        if (!@pwent) {die "Invalid username: root\n";}
        if (crypt($ARGV[0], $pwent[1]) eq $pwent[1]) {
            exit(0);
        } else {
            print STDERR "Invalid password for root\n";
            exit(1);
        }
    ' "$senha"
}

# Função para validar o código 2FA
chkRoot2FA() {

    # Lê a chave secreta do arquivo
    local secret_key

    # Verifica se o arquivo da chave secreta existe
    if [ ! -f "$SECRET_KEY_FILE" ]; then
        # Solicita a chave secreta para autenticacao 2FA
        read -p "Digite o código 2FA: " secret_key
    else
        # Obtem a chave secreta a partir do arquivo
        secret_key=$(&lt;"$SECRET_KEY_FILE")
    fi
    
    # Solicita o código 2FA
    read -p "Digite o código 2FA: " codigo_2fa

    # Verifica o código 2FA usando oathtool
    oathtool --totp -b "$secret_key" | grep -q "^$codigo_2fa$"
    return $?
}

# Captura do sinal SIGINT (Ctrl+C)
trap '' INT

# Loop principal para autenticação
while true; do
    if chkRootPWD; then
        echo -e "\nSenha correta."
        if chkRoot2FA; then
            echo "Autenticação 2FA correta. Bem-vindo ao terminal."
            exit 0
        else
            echo "Código 2FA incorreto. Tente novamente."
        fi
    else
        echo -e "\nSenha incorreta. Tente novamente."
    fi
done

```

OU, Crie um script chamado `login.lua`:

```lua
#!/usr/bin/lua

local posix = require("posix")

-- Caminho para o arquivo da chave secreta
SECRET_KEY_FILE = "/root/2FAsecret_key.txt"

-- Função para validar a senha do root usando Perl
function chkRootPWD()
    io.write("Digite a senha do root: ")
    os.execute("stty -echo")  -- Desativar a exibição de entrada
    local senha = io.read("*l")
    os.execute("stty echo")  -- Reativar a exibição de entrada
    print()

    -- Executa a verificação da senha usando um comando Perl
    local cmd = string.format(
        'perl -e \'use strict; use warnings; my @pwent = getpwnam("root"); if (!@pwent) {die "Invalid username: root\\n";} if (crypt("$ARGV[0]", $pwent[1]) eq $pwent[1]) {exit(0);} else {print STDERR "Invalid password for root\\n"; exit(1);}\' "%s"',
        senha
    )
    local handle = io.popen(cmd)
    local result = handle:close()
    local exit_code = result and 0 or 1

    if exit_code == 0 then
        print("Senha válida")
        return true
    else
        print("Senha inválida")
        return false
    end
end

-- Função para validar o código 2FA
function chkRoot2FA()
    local secret_key

    -- Verifica se o arquivo da chave secreta existe
    local file = io.open(SECRET_KEY_FILE, "r")
    if file then
        secret_key = file:read("*all"):gsub("%s+", "")
        file:close()
    else
        io.write("Arquivo da chave secreta não encontrado. Digite a chave secreta para 2FA: ")
        secret_key = io.read("*l")
        -- Salva a chave secreta em um arquivo para futuras execuções
        file = io.open(SECRET_KEY_FILE, "w")
        file:write(secret_key)
        file:close()
    end

    io.write("Digite o código 2FA: ")
    local codigo_2fa = io.read("*l")

    -- Verifica o código 2FA usando `oathtool`
    local cmd = string.format("oathtool --totp -b %s", secret_key)
    local handle = io.popen(cmd)
    local resultado = handle:read("*a"):gsub("%s+", "")
    handle:close()

    if resultado == codigo_2fa then
        print("Código 2FA correto")
        return true
    else
        print("Código 2FA incorreto")
        return false
    end
end

-- Função para ignorar SIGINT (CTRL+C)
function ignoreSIGINT()
    posix.signal(posix.SIGINT, function() end)
end

-- Captura do sinal SIGINT (Ctrl+C)
ignoreSIGINT()

-- Loop principal para autenticação
while true do
    if chkRootPWD() then
        print("\nSenha correta.")
        if chkRoot2FA() then
            print("Autenticação 2FA correta. Bem-vindo ao terminal.")
            os.exit(0)
        else
            print("Código 2FA incorreto. Tente novamente.")
        end
    else
        print("\nSenha incorreta. Tente novamente.")
    end
end
```

### Passo 4: Testar o Script de Login

1. **Defina permissões de execução para o script**:
    ```bash
    chmod +x login.sh
    ```
   ou 
   ```bash
    chmod +x login.lua
   ```

3. **Execute o script de login**:
    ```bash
    ./login.sh
    ```
    ou 
    ```bash
    ./login.lua
    ```

4. **Configure o aplicativo de 2FA** (como Microsoft Authenticator, Google Authenticator ou Authy) com a chave secreta armazenada em `2FAsecret_key.txt`.

5. Configure o script para ser executado no login:
    Edite o arquivo .bashrc do root:
    ```bash
    nano /root/.bashrc
    ```
    Adicione a seguinte linha ao final do arquivo:
    ```bash
    /root/login.sh
    ```
    ou
    ```bash
    /root/login.lua
    ```

    Teste a configuração:
    Feche o terminal WSL e abra novamente com o comando:
    ```bash
    wsl --user root
    ```

### Passo 5: Garanta que os scripts não possam ser acessados via \\wsl.localhost\ no windows

1. **Defina o usuário padrao
```bash
sudo editor /etc/wsl.conf
```
```bash
[user]
default=<NonRootUser>
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

## Referência:
[BlackTDN :: Como Forçar a Solicitação da Senha ao Acessar o WSL como Root](https://www.blacktdn.com.br/2024/06/blacktdn-como-forcar-solicitacao-da.html)

---
