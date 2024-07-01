#!/usr/bin/lua

local posix = require("posix")

-- Caminho para o arquivo da chave secreta
SECRET_KEY_FILE = "/root/2FA/lua_2FAsecret_key.txt"

-- Função para validar a senha do root usando Perl
function chkRootPWD()
  
    io.write("Digite a senha do root: ")
    os.execute("stty -echo")  -- Desativar a exibição de entrada
    local senha = io.read("*l")
    os.execute("stty echo")  -- Reativar a exibição de entrada
    print()

    -- Executa a verificação da senha usando um comando Perl
    local cmd = string.format(
        'perl "/root/scripts/perl/check_password.pl" "%s"',
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
    end

    io.write("Digite o código 2FA: ")
    local codigo_2fa = io.read("*l")

    -- Verifica o código 2FA usando `oathtool`
    local cmd = string.format("oathtool --totp -b %s", secret_key)
    local handle = io.popen(cmd)
    local resultado = handle:read("*a"):gsub("%s+", "")
    handle:close()

    if resultado == codigo_2fa then
        if not file then
            -- Salva a chave secreta em um arquivo para futuras execuções
            file = io.open(SECRET_KEY_FILE, "w")
            file:write(secret_key)
            file:close()
        end
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
