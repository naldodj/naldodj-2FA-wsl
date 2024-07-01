#!/usr/bin/lua

local SECRET_KEY_FILE = "/root/2FA/lua_2FAsecret_key.txt"

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
