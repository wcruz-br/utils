#!/bin/bash

# Obtém o diretório onde este script está localizado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define o caminho do interpretador Python do virtualenv
VENV_PYTHON="${SCRIPT_DIR}/.venv/bin/python"

# Verifica se o Python do virtualenv existe
if [ ! -f "$VENV_PYTHON" ]; then
    echo "Erro: Python do virtualenv não encontrado em: $VENV_PYTHON"
    echo "Certifique-se que o virtualenv está criado no diretório .venv"
    exit 1
fi

# Executa o script Python passando todos os argumentos recebidos
exec "$VENV_PYTHON" "${SCRIPT_DIR}/html_to_markdown.py" "$@"
