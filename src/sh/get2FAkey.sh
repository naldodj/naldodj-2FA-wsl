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
    echo "$base32_secret" > "$SECRET_KEY_FILE"

    # Define permissões restritivas para o arquivo
    chmod 600 "$SECRET_KEY_FILE"

    echo "Chave secreta gerada e armazenada em $SECRET_KEY_FILE."
fi
