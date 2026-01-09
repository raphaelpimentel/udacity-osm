#!/bin/bash

# Script de teste para o workflow Vespucio Scrape Post
# Testa scraping de um post real sem precisar de Supabase

set -e

# Configuração
N8N_URL="${N8N_URL:-http://localhost:5678}"
WEBHOOK_PATH="/webhook/vespucio-scrape-post"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}🧪 Teste: Vespucio Scrape Post${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Teste 1: Blog técnico (TechCrunch)
echo -e "${GREEN}📝 Teste 1: Blog de tecnologia${NC}"
echo "URL: https://techcrunch.com/"
echo ""

RESPONSE=$(curl -s -X POST "${N8N_URL}${WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-techcrunch-001",
    "url": "https://techcrunch.com/"
  }')

echo "Resposta:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""
echo "---"
echo ""

# Teste 2: Blog de viagem
echo -e "${GREEN}📝 Teste 2: Blog de viagem${NC}"
echo "URL: https://www.nomadicmatt.com/travel-blogs/"
echo ""

RESPONSE=$(curl -s -X POST "${N8N_URL}${WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-travel-001",
    "url": "https://www.nomadicmatt.com/travel-blogs/"
  }')

echo "Resposta:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""
echo "---"
echo ""

# Teste 3: Blog brasileiro (exemplo)
echo -e "${GREEN}📝 Teste 3: Blog brasileiro${NC}"
echo "URL: https://www.akitaonrails.com/"
echo ""

RESPONSE=$(curl -s -X POST "${N8N_URL}${WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-br-001",
    "url": "https://www.akitaonrails.com/"
  }')

echo "Resposta:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""
echo "---"
echo ""

# Teste 4: URL inválida (teste de erro)
echo -e "${YELLOW}📝 Teste 4: URL inválida (esperado: erro)${NC}"
echo "URL: https://site-que-nao-existe-xyz123.com/post"
echo ""

RESPONSE=$(curl -s -X POST "${N8N_URL}${WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-error-001",
    "url": "https://site-que-nao-existe-xyz123.com/post"
  }')

echo "Resposta:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""
echo "---"
echo ""

echo -e "${GREEN}✅ Testes concluídos!${NC}"
echo ""
echo -e "${YELLOW}📊 Próximos passos:${NC}"
echo "1. Vá para ${N8N_URL} e veja as execuções em 'Executions'"
echo "2. Verifique os dados extraídos em cada node"
echo "3. Confira se a IA categorizou corretamente (se Gemini configurado)"
echo ""
