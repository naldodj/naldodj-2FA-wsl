#!/bin/bash

# Desabilitar CTRL+C
trap '' SIGINT
trap '' INT TSTP

# Executar o script PowerShell
pwsh ./login.ps1 -NoExit

# Reabilitar CTRL+C
trap - SIGINT
trap - INT TSTP
