#!/bin/bash

# Script: generate_source_file.sh
# Descrição: Este script busca por arquivos de código e configuração em um diretório especificado
#            (ou no diretório atual por padrão) e concatena seus conteúdos em um único arquivo de saída.
#            Ele ignora diretórios especificados por padrões de exclusão.
# Parâmetros:
#   -h, -?, --help: Exibe esta mensagem de ajuda.
#   -d <diretorio_entrada>: Especifica o diretório base para a busca. Padrão: diretório atual (.)
#   -o <arquivo_saida>: Especifica o nome do arquivo de saída. Padrão: ./fontes.txt
#   -m "<mascara1>,<mascara2>,...": Especifica as máscaras de arquivo a serem incluídas na busca.
#                                   As máscaras podem ser separadas por vírgula ou espaço.
#                                   Padrão: "*.py,*.js,*.ts,*.json,*.yaml,*.yml,*.html,*.css,*.sh,Dockerfile,requirements.txt"
#   -x "<padrao1>,<padrao2>,...": Especifica padrões de diretório a serem excluídos da busca.
#                                   Os padrões podem ser separados por vírgula ou espaço.
#                                   Padrão: "*/.*" (ignora diretórios que começam com ponto)
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


# Função para exibir a mensagem de ajuda
show_help() {
    echo ""
    echo "Uso: $(basename "$0") [OPÇÕES]"
    echo ""
    echo "Este script busca por arquivos de código e configuração e concatena seus conteúdos."
    echo ""
    echo "Opções:"
    echo ""
    echo "  -h, -?, --help           Exibe esta mensagem de ajuda."
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
    echo "Exemplos:"
    echo "  $(basename "$0")"
    echo "  $(basename "$0") -d /caminho/para/projeto -o saida.txt"
    echo "  $(basename "$0") -m \"*.c,*.h\" -o codigo_c.txt"
    echo "  $(basename "$0") -d /srv/app -m \"*.py,requirements.txt,Dockerfile\" -o app_fontes.txt"
    echo "  $(basename "$0") -x \"*/.git/*,*/temp/*\""
    echo ""
}

# Verifica se o primeiro argumento é --help
if [ "$1" == "--help" ]; then
    show_help
    exit 0
fi

# Analisa as opções da linha de comando (incluindo -? e -x)
while getopts "ho:d:m:x:?" opt; do
    case $opt in
        h|\?) # Trata -h e -?
            show_help
            exit 0
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
        :)
            echo "Erro: Opção -$OPTARG requer um argumento." >&2
            show_help
            exit 1
            ;;
        \?)
            echo "Erro: Opção inválida: -$OPTARG" >&2
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

# Pede confirmação
read -p "Vou colocar os conteúdos dos arquivos encontrados a partir de '$input_dir' no arquivo '$output_file'. Confirma? (s/N) " -n 1 -r
echo # Move para a nova linha
if [[ ! $REPLY =~ ^[Ss]$ ]]
then
    echo "Operação cancelada pelo usuário."
    echo ""
    exit 1
fi

# Limpa o arquivo de saída
true > "$output_file"

echo "Procurando arquivos com máscaras '$file_masks' em '$input_dir', excluindo padrões '$exclude_patterns'..."

# Constrói a expressão -path ... -prune -o para o find dinamicamente a partir dos padrões de exclusão
exclude_conditions=""
# Substitui vírgulas por espaços e remove espaços extras para iterar sobre os padrões
IFS=, read -ra exclude_array <<< "$exclude_patterns"
for pattern in "${exclude_array[@]}"; do
    # Remove espaços em branco no início e fim do padrão
    trimmed_pattern=$(echo "$pattern" | xargs)
    if [ -n "$trimmed_pattern" ]; then # Garante que o padrão não está vazio após trimming
        # Adiciona a condição de exclusão e o -prune -o
        printf -v exclude_conditions '%s -path "%s" -prune -o' "$exclude_conditions" "$trimmed_pattern"
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

# Comando find completo: <diretorio_entrada> <condições_exclusao> \( <condições_nome> \) -type f -print
# Usar eval é necessário aqui porque as strings de condições contêm opções do find e precisam ser analisadas pelo shell.
# Isso geralmente é seguro se as máscaras/padrões de entrada forem controlados.
find_cmd="find \"$input_dir\" $exclude_conditions \( $name_conditions \) -type f -print"

# Executa o find e processa os arquivos encontrados
file_count=0
# Usa um loop while para ler nomes de arquivos da saída do find
# Usar substituição de processo <(...) é mais seguro do que redirecionar diretamente para while read
# porque executa o loop while no shell atual, preservando variáveis como file_count.
while read -r file; do
    # Verifica se o arquivo existe e é legível antes de processar
    if [ -f "$file" ] && [ -r "$file" ]; then
        {
            echo "----- $file -----"
            cat "$file"
            echo ""
        } >> "$output_file"
        file_count=$((file_count + 1))
    else
        echo "Aviso: Pulando arquivo ilegível ou inexistente: $file" >&2
    fi
done < <(eval "$find_cmd")

echo "Arquivo '$output_file' gerado com sucesso em $(pwd)."
echo ""
echo "Número de arquivos processados: $file_count"
echo ""

exit 0
