#!/bin/bash

OUTPUT_FILE="fontes.txt"

# Pede confirmação
read -p "Vou colocar todos os arquivos fontes e docker a partir deste diretório no arquivo '$OUTPUT_FILE'. Confirma? (s/N) " -n 1 -r
echo # Move para a nova linha
if [[ ! $REPLY =~ ^[Ss]$ ]]
then
    echo "Operação cancelada."
    exit 1
fi

# Limpa o arquivo de saída
true > "$OUTPUT_FILE"

echo "Procurando arquivos .py, .js, .json, .html, .css, .yaml, .yml e Dockerfile no diretório atual e subdiretórios..."
# Gera um arquivo com todos os fontes, ignorando diretórios ocultos (que começam com .)
find . -path '*/.*' -prune -o \( -name "*.py" -o -name "*.js" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.html" -o -name "*.css" -o -name "Dockerfile" \) -type f ! -path "*/__pycache__/*" ! -path "*/node_modules/*" ! -path "*/dist*/*" -exec sh -c '{ echo "----- $1 -----"; cat "$1"; echo ""; } >> "$2"' _ {} "$OUTPUT_FILE" \;

echo "Verificando arquivos de configuração..."

# Acrescenta o Dockerfile se existir
if [ -f "Dockerfile" ]; then
    {
        echo "----- Dockerfile -----"
        cat Dockerfile
        echo ""
    } >> "$OUTPUT_FILE"
    echo "Dockerfile adicionado."
fi

# Acrescenta o requirements.txt se existir
if [ -f "requirements.txt" ]; then
    {
        echo "----- requirements.txt -----"
        cat requirements.txt
        echo ""
    } >> "$OUTPUT_FILE"
    echo "requirements.txt adicionado."
fi

echo "Arquivo $OUTPUT_FILE gerado com sucesso no diretório atual."
