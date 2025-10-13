#!/bin/bash
# -----------------------------------------------------------------------------
# Script: merge_markdowns.sh
# Descrição: Junta todos os arquivos .md de um diretório em um único arquivo.
# Uso: ./merge_markdowns.sh [diretório_origem] [arquivo_destino]
# Exemplo: ./merge_markdowns.sh ./docs ./saida_unica.md
# -----------------------------------------------------------------------------

# Verifica se dois parâmetros foram passados
if [ $# -ne 2 ]; then
  echo "Uso incorreto."
  echo "Exemplo: $0 <diretório_origem> <arquivo_destino>"
  exit 1
fi

# Atribui os parâmetros a variáveis com nomes claros
source_dir="$1"
output_file="$2"

# Verifica se o diretório existe
if [ ! -d "$source_dir" ]; then
  echo "Erro: o diretório '$source_dir' não existe."
  exit 1
fi

# Remove o arquivo de saída, se já existir
if [ -f "$output_file" ]; then
  rm "$output_file"
fi

# Mensagem inicial
echo "Iniciando a junção dos arquivos .md do diretório '$source_dir'..."

# Itera sobre todos os arquivos .md em ordem alfabética
for file in "$source_dir"/*.md; do
  if [ -f "$file" ]; then
    echo -e "\n\n---\n# Arquivo: $(basename "$file")\n" >> "$output_file"
    cat "$file" >> "$output_file"
  fi
done

# Mensagem final
echo "Todos os arquivos foram combinados em: $output_file"
