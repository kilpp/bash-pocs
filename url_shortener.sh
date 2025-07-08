#!/bin/bash

# Encurtador de URL em Shell-Bash Script
# Autor: Manus AI
# Versão: 1.0

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_FILE="$SCRIPT_DIR/urls.db"
CONFIG_FILE="$SCRIPT_DIR/config.conf"
BASE_URL="http://short.ly/"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir ajuda
show_help() {
    echo -e "${BLUE}Encurtador de URL em Shell-Bash Script${NC}"
    echo ""
    echo "Uso: $0 [OPÇÃO] [ARGUMENTO]"
    echo ""
    echo "Opções:"
    echo "  -s, --shorten URL    Encurtar uma URL"
    echo "  -e, --expand CODE    Expandir um código curto"
    echo "  -l, --list          Listar todas as URLs encurtadas"
    echo "  -r, --remove CODE   Remover uma URL encurtada"
    echo "  --stats             Mostrar estatísticas"
    echo "  -h, --help          Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 -s \"https://www.exemplo.com/pagina/muito/longa\""
    echo "  $0 -e \"abc123\""
    echo "  $0 -l"
    echo "  $0 -r \"abc123\""
}

# Função para gerar código curto aleatório
generate_short_code() {
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local code=""
    local length=6
    
    while true; do
        code=""
        for i in $(seq 1 $length); do
            code="${code}${chars:$((RANDOM % ${#chars})):1}"
        done
        
        # Verificar se o código já existe
        if [[ ! -f "$DB_FILE" ]] || ! grep -q "^$code|" "$DB_FILE"; then
            echo "$code"
            return 0
        fi
    done
}

# Função para validar URL
validate_url() {
    local url="$1"
    if [[ $url =~ ^https?:// ]]; then
        return 0
    else
        return 1
    fi
}

# Função para inicializar arquivos
init_files() {
    # Criar arquivo de banco de dados se não existir
    if [[ ! -f "$DB_FILE" ]]; then
        touch "$DB_FILE"
    fi
    
    # Criar arquivo de configuração se não existir
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
# Configurações do Encurtador de URL
BASE_URL=$BASE_URL
CREATED=$(date)
EOF
    fi
}

# Função para encurtar URL
shorten_url() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo -e "${RED}Erro: URL não fornecida${NC}"
        return 1
    fi
    
    if ! validate_url "$url"; then
        echo -e "${RED}Erro: URL inválida. Use http:// ou https://${NC}"
        return 1
    fi
    
    # Verificar se a URL já foi encurtada
    if [[ -f "$DB_FILE" ]]; then
        local existing_code=$(grep "|$url|" "$DB_FILE" | cut -d'|' -f1 | head -1)
        if [[ -n "$existing_code" ]]; then
            echo -e "${YELLOW}URL já encurtada:${NC}"
            echo -e "${GREEN}$BASE_URL$existing_code${NC}"
            return 0
        fi
    fi
    
    local code=$(generate_short_code)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Salvar no banco de dados
    echo "$code|$url|$timestamp|0" >> "$DB_FILE"
    
    echo -e "${GREEN}URL encurtada com sucesso!${NC}"
    echo -e "${BLUE}URL original:${NC} $url"
    echo -e "${BLUE}URL encurtada:${NC} ${GREEN}$BASE_URL$code${NC}"
    echo -e "${BLUE}Código:${NC} $code"
}

# Função para expandir URL
expand_url() {
    local code="$1"
    
    if [[ -z "$code" ]]; then
        echo -e "${RED}Erro: Código não fornecido${NC}"
        return 1
    fi
    
    if [[ ! -f "$DB_FILE" ]]; then
        echo -e "${RED}Erro: Nenhuma URL encurtada encontrada${NC}"
        return 1
    fi
    
    local line=$(grep "^$code|" "$DB_FILE")
    if [[ -z "$line" ]]; then
        echo -e "${RED}Erro: Código '$code' não encontrado${NC}"
        return 1
    fi
    
    local url=$(echo "$line" | cut -d'|' -f2)
    local timestamp=$(echo "$line" | cut -d'|' -f3)
    local count=$(echo "$line" | cut -d'|' -f4)
    
    # Incrementar contador de acessos
    local new_count=$((count + 1))
    # Usar awk para atualizar o contador de forma mais segura
    awk -F'|' -v code="$code" -v new_count="$new_count" '
        $1 == code { $4 = new_count }
        { print $1"|"$2"|"$3"|"$4 }
    ' "$DB_FILE" > "${DB_FILE}.tmp" && mv "${DB_FILE}.tmp" "$DB_FILE"
    
    echo -e "${GREEN}URL encontrada!${NC}"
    echo -e "${BLUE}Código:${NC} $code"
    echo -e "${BLUE}URL original:${NC} ${GREEN}$url${NC}"
    echo -e "${BLUE}Criada em:${NC} $timestamp"
    echo -e "${BLUE}Acessos:${NC} $new_count"
}

# Função para listar URLs
list_urls() {
    if [[ ! -f "$DB_FILE" ]] || [[ ! -s "$DB_FILE" ]]; then
        echo -e "${YELLOW}Nenhuma URL encurtada encontrada${NC}"
        return 0
    fi
    
    echo -e "${BLUE}URLs Encurtadas:${NC}"
    echo ""
    printf "%-8s %-50s %-20s %-8s\n" "Código" "URL Original" "Data/Hora" "Acessos"
    echo "$(printf '%*s' 86 '' | tr ' ' '-')"
    
    while IFS='|' read -r code url timestamp count; do
        # Truncar URL se muito longa
        if [[ ${#url} -gt 47 ]]; then
            url="${url:0:44}..."
        fi
        printf "%-8s %-50s %-20s %-8s\n" "$code" "$url" "$timestamp" "$count"
    done < "$DB_FILE"
}

# Função para remover URL
remove_url() {
    local code="$1"
    
    if [[ -z "$code" ]]; then
        echo -e "${RED}Erro: Código não fornecido${NC}"
        return 1
    fi
    
    if [[ ! -f "$DB_FILE" ]]; then
        echo -e "${RED}Erro: Nenhuma URL encurtada encontrada${NC}"
        return 1
    fi
    
    if ! grep -q "^$code|" "$DB_FILE"; then
        echo -e "${RED}Erro: Código '$code' não encontrado${NC}"
        return 1
    fi
    
    # Remover linha do arquivo
    sed -i "/^$code|/d" "$DB_FILE"
    
    echo -e "${GREEN}URL com código '$code' removida com sucesso!${NC}"
}

# Função para mostrar estatísticas
show_stats() {
    if [[ ! -f "$DB_FILE" ]] || [[ ! -s "$DB_FILE" ]]; then
        echo -e "${YELLOW}Nenhuma URL encurtada encontrada${NC}"
        return 0
    fi
    
    local total_urls=$(wc -l < "$DB_FILE")
    local total_clicks=0
    local most_clicked_code=""
    local most_clicked_count=0
    
    while IFS='|' read -r code url timestamp count; do
        total_clicks=$((total_clicks + count))
        if [[ $count -gt $most_clicked_count ]]; then
            most_clicked_count=$count
            most_clicked_code=$code
        fi
    done < "$DB_FILE"
    
    echo -e "${BLUE}Estatísticas do Encurtador de URL:${NC}"
    echo ""
    echo -e "${GREEN}Total de URLs encurtadas:${NC} $total_urls"
    echo -e "${GREEN}Total de cliques:${NC} $total_clicks"
    if [[ $total_urls -gt 0 ]]; then
        echo -e "${GREEN}Média de cliques por URL:${NC} $((total_clicks / total_urls))"
    fi
    if [[ -n "$most_clicked_code" ]]; then
        echo -e "${GREEN}URL mais clicada:${NC} $most_clicked_code ($most_clicked_count cliques)"
    fi
}

# Função principal
main() {
    init_files
    
    case "$1" in
        -s|--shorten)
            shorten_url "$2"
            ;;
        -e|--expand)
            expand_url "$2"
            ;;
        -l|--list)
            list_urls
            ;;
        -r|--remove)
            remove_url "$2"
            ;;
        --stats)
            show_stats
            ;;
        -h|--help|"")
            show_help
            ;;
        *)
            echo -e "${RED}Opção inválida: $1${NC}"
            echo "Use '$0 --help' para ver as opções disponíveis"
            exit 1
            ;;
    esac
}

# Executar função principal com todos os argumentos
main "$@"

