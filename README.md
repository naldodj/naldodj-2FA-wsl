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

Execute o script para gerar e armazenar a chave secreta:

```bash
chmod +x get2FAkey.sh
./get2FAkey.sh
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

### Passo 4: Testar o Script de Login

1. **Defina permissões de execução para o script**:
    ```bash
    chmod +x login.sh
    ```

2. **Execute o script de login**:
    ```bash
    ./login.sh
    ```

3. **Configure o aplicativo de 2FA** (como Microsoft Authenticator, Google Authenticator ou Authy) com a chave secreta armazenada em `2FAsecret_key.txt`.

4. Configure o script para ser executado no login:
    Edite o arquivo .bashrc do root:
    ```bash
    nano /root/.bashrc
    ```bash
    Adicione a seguinte linha ao final do arquivo:
    ```bash
    /root/login.sh
    ```bash

    Teste a configuração:
    Feche o terminal WSL e abra novamente com o comando:
    ```bash
        wsl --user root
    ```

### Conclusão

Com essas etapas, você configurou um sistema de autenticação robusto para o usuário root no WSL, utilizando uma senha e autenticação de dois fatores (2FA). Isso adiciona uma camada extra de segurança, protegendo contra acessos não autorizados. Lembre-se de armazenar a chave secreta em um local seguro e ajustar as permissões dos arquivos conforme necessário.

Essa configuração pode ser adaptada e aprimorada conforme suas necessidades específicas, mas serve como uma base sólida para garantir a segurança no uso do WSL.

---

## Referência:
[BlackTDN :: Como Forçar a Solicitação da Senha ao Acessar o WSL como Root](https://www.blacktdn.com.br/2024/06/blacktdn-como-forcar-solicitacao-da.html)

---
