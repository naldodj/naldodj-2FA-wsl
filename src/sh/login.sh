#!/bin/bash

# Caminho para o arquivo da chave secreta
SECRET_KEY_FILE="/root/2FA/sh_2FAsecret_key.txt"

# Função para validar a senha do root usando Perl
chkRootPWD() {
    # Solicita a senha de forma segura e armazena em uma variável
    read -s -p "Digite a senha do root: " senha
    # Executa a validação da senha usando Perl
    perl "/root/scripts/perl/check_password.pl" "$senha"
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
        secret_key=$(<"$SECRET_KEY_FILE")
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
