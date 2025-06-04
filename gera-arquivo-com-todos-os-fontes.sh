#!/bin/bash

# Script: generate_source_file.sh
# Descrição: Este script busca por arquivos de código e configuração em um diretório especificado
#            (ou no diretório atual por padrão) e concatena seus conteúdos em um único arquivo de saída.
#            Ele ignora diretórios especificados por padrões de exclusão.
#            Sempre insere no início do arquivo gerado a árvore de diretórios (tree -d).
#            Se chamado sem parâmetros, exibe o help.
#            Parâmetro --default executa com os padrões pré-definidos.
# Parâmetros:
#   -h, -?, --help: Exibe esta mensagem de ajuda.
#   --default: Executa com todos os parâmetros padrão, sem pedir confirmação.
#   -d <diretorio_entrada>: Especifica o diretório base para a busca. Padrão: diretório atual (.)
#   -o <arquivo_saida>: Especifica o nome do arquivo de saída. Padrão: ./fontes.txt
#   -m "<mascara1>,<mascara2>,...": Especifica as máscaras de arquivo a serem incluídas na busca.
#                                   As máscaras podem ser separadas por vírgula ou espaço.
#   -x "<padrao1>,<padrao2>,...": Especifica padrões de diretório a serem excluídos da busca.
#                                   Os padrões podem ser separados por vírgula ou espaço.
#   -a: Ativa o modo de acréscimo (append). Se presente, o arquivo de saída não é recriado,
#       e o novo conteúdo é adicionado ao final do arquivo existente. Por padrão, o arquivo
#       é recriado a cada execução.
# Retorno: Cria o arquivo de saída especificado com o conteúdo dos arquivos encontrados.
#          Retorna 0 em caso de sucesso, 1 em caso de cancelamento ou erro.

# Valores padrão
input_dir=$(pwd)
output_file="$input_dir/fontes.txt"

# Máscaras padrão separadas por vírgula
default_masks="*.py,*.js,*.ts,*.json,*.yaml,*.yml,*.html,*.css,*.sh,Dockerfile,requirements.txt"
file_masks="$default_masks"

# Padrões de exclusão de diretórios padrão (separados por vírgula)
default_exclude_patterns="*/.*,*/__pycache__/*,*/node_modules/*,*/dist*/*"
exclude_patterns="$default_exclude_patterns"

# Modo de acréscimo (append) - padrão é false (recriar arquivo)
append_mode=false

# Função para exibir a mensagem de ajuda
show_help() {
    echo ""
    echo "Uso: $(basename "$0") [OPÇÕES]"
    echo ""
    echo "Este script busca por arquivos de código e configuração e concatena seus conteúdos."
    echo "Sempre insere no início do arquivo gerado a árvore de diretórios (tree -d)."
    echo ""
    echo "Opções:"
    echo ""
    echo "  -h, -?, --help           Exibe esta mensagem de ajuda."
    echo ""
    echo "  --default                Executa com todos os parâmetros padrão, sem pedir confirmação."
    echo ""
    echo "  -d <diretorio_entrada>   Especifica o diretório base para a busca, que inclui subdiretórios."
    echo "                           Padrão: diretório atual ($input_dir)"
    echo ""
    echo "  -o <arquivo_saida>       Especifica o nome do arquivo de saída."
    echo "                           Padrão: $output_file"
    echo ""
    echo "  -m \"<mascara1>,...\"      Especifica as máscaras de arquivo (entre aspas)."
    echo "                           Padrão: \"$default_masks\""
    echo ""
    echo "  -x \"<padrao1>,...\"       Especifica padrões de diretório a serem excluídos (entre aspas)."
    echo "                           Padrão: \"$default_exclude_patterns\""
    echo ""
    echo "  -a                       Ativa o modo de acréscimo (append). O arquivo de saída não é"
    echo "                           recriado, e o conteúdo é adicionado ao final do arquivo existente."
    echo "                           Por padrão, o arquivo é recriado."
    echo ""
    echo "Exemplos:"
    echo "  $(basename "$0") --default"
    echo "  $(basename "$0")"
    echo "  $(basename "$0") -d /caminho/para/projeto -o saida.txt"
    echo "  $(basename "$0") -m \"*.c,*.h\" -o codigo_c.txt"
    echo "  $(basename "$0") -d /srv/app -m \"*.py,requirements.txt,Dockerfile\" -o app_fontes.txt"
    echo "  $(basename "$0") -x \"*/.git/*,*/temp/*\""
    echo "  $(basename "$0") -a -o log.txt"
    echo ""
}

# Se não houver parâmetros, mostra o help e sai
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Verifica se o primeiro argumento é --help
if [ "$1" == "--help" ]; then
    show_help
    exit 0
fi

# Verifica se o primeiro argumento é --default
if [ "$1" == "--default" ]; then
    # Executa com todos os padrões, sem confirmação
    input_dir=$(pwd)
    output_file="$input_dir/fontes.txt"
    file_masks="$default_masks"
    exclude_patterns="$default_exclude_patterns"
    append_mode=false
    shift
    skip_confirm=true
else
    skip_confirm=false
fi

# Analisa as opções da linha de comando
while getopts "h?o:d:m:x:a" opt; do # Adicionado 'a' aqui
    case $opt in
        h)  # Trata -h
            show_help
            exit 0
            ;;
        \?) # Trata -? e opções inválidas
            if [ "$OPTARG" = "?" ]; then
                show_help
                exit 0
            else
                echo "Erro: Opção inválida: -$OPTARG" >&2
                show_help
                exit 1
            fi
            ;;
        o)
            output_file="$OPTARG"
            ;;
        d)
            input_dir="$OPTARG"
            ;;
        m)
            file_masks="$OPTARG"
            ;;
        x)
            exclude_patterns="$OPTARG"
            ;;
        a) # Trata -a
            append_mode=true
            ;;
        :)
            echo "Erro: Opção -$OPTARG requer um argumento." >&2
            show_help
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

echo ""

# Verifica se o diretório de entrada existe
if [ ! -d "$input_dir" ]; then
    echo "Erro: Diretório de entrada não encontrado: $input_dir" >&2
    echo ""
    exit 1
fi

# Pede confirmação, exceto se skip_confirm=true (--default)
if [ "$skip_confirm" != "true" ]; then
    read -p "Vou colocar os conteúdos dos arquivos encontrados a partir de '$input_dir' no arquivo '$output_file'. Confirma? (s/N) " -n 1 -r
    echo # Move para a nova linha
    if [[ ! $REPLY =~ ^[Ss]$ ]]
    then
        echo "Operação cancelada pelo usuário."
        echo ""
        exit 1
    fi
fi

# Limpa o arquivo de saída APENAS se não estiver no modo append
if [ "$append_mode" = false ]; then
    echo "Criando arquivo de saída: '$output_file'"
    true > "$output_file"
else
    echo "Adicionando ao arquivo de saída existente: '$output_file'"
fi
echo ""

# Adiciona a árvore de diretórios no início do arquivo de saída
echo "Árvore de diretórios de '$input_dir':" >> "$output_file"
tree -d "$input_dir" >> "$output_file" 2>/dev/null
echo "" >> "$output_file"

echo "Procurando arquivos com máscaras '$file_masks' em '$input_dir', excluindo padrões '$exclude_patterns'..."

# Constrói a expressão -path ... -prune -o para o find dinamicamente a partir dos padrões de exclusão
exclude_conditions=""

# Primeiro adiciona a exclusão do arquivo de saída (convertendo para caminho relativo)
output_relative=$(realpath --relative-to="$input_dir" "$output_file")

# Adiciona os padrões de exclusão (incluindo o arquivo de saída)
IFS=, read -ra exclude_array <<< "${exclude_patterns},${output_relative}"
for pattern in "${exclude_array[@]}"; do
    # Remove espaços em branco no início e fim do padrão
    trimmed_pattern=$(echo "$pattern" | xargs)
    if [ -n "$trimmed_pattern" ]; then
        # Se for caminho absoluto, converte para relativo ao input_dir
        if [[ "$trimmed_pattern" = /* ]]; then
            trimmed_pattern=$(realpath --relative-to="$input_dir" "$trimmed_pattern")
        fi
        # Adiciona ./ no início do padrão se não começar com * ou ./
        if [[ ! "$trimmed_pattern" == \** && "$trimmed_pattern" != ./* ]]; then
            trimmed_pattern="./$trimmed_pattern"
        fi
        # Adiciona a condição de exclusão (com -o se não for o primeiro)
        if [ -z "$exclude_conditions" ]; then
            exclude_conditions="-path \"$trimmed_pattern\" -prune"
        else
            exclude_conditions="$exclude_conditions -o -path \"$trimmed_pattern\" -prune"
        fi
    fi
done

# Constrói a expressão -name para o find dinamicamente a partir das máscaras de arquivo
name_conditions=""
first_mask=true
# Substitui vírgulas por espaços e remove espaços extras para iterar sobre as máscaras
IFS=, read -ra masks_array <<< "$file_masks"
for mask in "${masks_array[@]}"; do
    # Remove espaços em branco no início e fim da máscara
    trimmed_mask=$(echo "$mask" | xargs)
    if [ -n "$trimmed_mask" ]; then # Garante que a máscara não está vazia após trimming
        if [ "$first_mask" = true ]; then
            printf -v name_conditions '%s' "-name \"$trimmed_mask\""
            first_mask=false
        else
            printf -v name_conditions '%s -o -name "%s"' "$name_conditions" "$trimmed_mask"
        fi
    fi
done

# Verifica se alguma máscara foi processada
if [ -z "$name_conditions" ]; then
    echo "Erro: Nenhuma máscara de arquivo válida especificada após processamento." >&2
    echo ""
    exit 1
fi

# Constrói o comando find completo
find_cmd="find \"$input_dir\" \( $exclude_conditions \) -o \( $name_conditions \) -type f -print"

# echo ""
# echo "Comando find gerado: $find_cmd"

# Executa o find e processa os arquivos encontrados
file_count=0

# Usa um loop while para ler nomes de arquivos da saída do find
# Usar substituição de processo <(...) é mais seguro do que redirecionar diretamente para while read
# porque executa o loop enquanto no shell atual, preservando variáveis como file_count.
while read -r file; do
    # Garante que o arquivo de saída nunca será processado, comparando caminhos absolutos
    if [ "$(realpath "$file")" = "$(realpath "$output_file")" ]; then
        continue
    fi

    # Verifica se o arquivo existe e é legível antes de processar
    if [ -f "$file" ] && [ -r "$file" ]; then
        # Converte o caminho completo para relativo em relação ao diretório de entrada
        relative_path=$(realpath --relative-to="$input_dir" "$file")
        {
            echo "----- $relative_path -----"
            cat "$file"
            echo ""
        } >> "$output_file"
        file_count=$((file_count + 1))
    else
        echo "Aviso: Pulando arquivo ilegível ou inexistente: $file" >&2
    fi
done < <(eval "$find_cmd")

echo ""
echo "Arquivo '$output_file' gerado com sucesso em $(pwd)."
echo ""
echo "Número de arquivos processados: $file_count"
echo ""

exit 0
