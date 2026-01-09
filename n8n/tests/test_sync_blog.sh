#!/bin/bash

# Script de teste para o workflow Vespucio Sync Blog
# ATENÇÃO: Requer Supabase configurado e blog cadastrado

set -e

# Configuração
N8N_URL="${N8N_URL:-http://localhost:5678}"
WEBHOOK_PATH="/webhook/vespucio-sync-blog"

# IMPORTANT: Substitua pelos seus UUIDs reais do Supabase
BLOG_ID="${BLOG_ID:-}"
USER_ID="${USER_ID:-}"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}🧪 Teste: Vespucio Sync Blog${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Valida se as variáveis estão configuradas
if [ -z "$BLOG_ID" ] || [ -z "$USER_ID" ]; then
  echo -e "${RED}❌ ERRO: Variáveis não configuradas${NC}"
  echo ""
  echo "Configure antes de executar:"
  echo ""
  echo "  export BLOG_ID='uuid-do-blog'"
  echo "  export USER_ID='uuid-do-usuario'"
  echo ""
  echo "Ou execute inline:"
  echo ""
  echo "  BLOG_ID='xxx' USER_ID='yyy' ./test_sync_blog.sh"
  echo ""
  echo -e "${YELLOW}📝 Como obter os UUIDs:${NC}"
  echo ""
  echo "1. Acesse seu Supabase: https://supabase.com/dashboard"
  echo "2. Vá em SQL Editor"
  echo "3. Execute:"
  echo ""
  echo "   -- Crie um blog de teste"
  echo "   INSERT INTO blogs (user_id, base_url, status)"
  echo "   VALUES ("
  echo "     (SELECT id FROM auth.users LIMIT 1),"
  echo "     'https://blog.google',"
  echo "     'new'"
  echo "   )"
  echo "   RETURNING id, user_id;"
  echo ""
  echo "4. Copie os UUIDs retornados"
  echo ""
  exit 1
fi

echo -e "${GREEN}📋 Configuração:${NC}"
echo "N8N URL: $N8N_URL"
echo "Blog ID: $BLOG_ID"
echo "User ID: $USER_ID"
echo ""

echo -e "${YELLOW}🚀 Iniciando sync do blog...${NC}"
echo ""

RESPONSE=$(curl -s -X POST "${N8N_URL}${WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d "{
    \"blog_id\": \"$BLOG_ID\",
    \"user_id\": \"$USER_ID\"
  }")

echo -e "${GREEN}📥 Resposta do webhook:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Verifica se teve sucesso
if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✅ Sync iniciado com sucesso!${NC}"
  echo ""
  echo -e "${YELLOW}📊 O que está acontecendo agora:${NC}"
  echo ""
  echo "1. ✅ Validou blog & ownership"
  echo "2. ⏳ Descobrindo sitemap..."
  echo "3. ⏳ Extraindo URLs..."
  echo "4. ⏳ Inserindo novos posts..."
  echo "5. ⏳ Scrapenado cada post..."
  echo ""
  echo -e "${YELLOW}🔍 Como acompanhar:${NC}"
  echo ""
  echo "1. Acesse: ${N8N_URL}/workflow/executions"
  echo "2. Veja a execução em andamento"
  echo "3. Ou consulte o Supabase:"
  echo ""
  echo "   -- Ver status do blog"
  echo "   SELECT * FROM blogs WHERE id = '$BLOG_ID';"
  echo ""
  echo "   -- Ver posts descobertos"
  echo "   SELECT url, status, title FROM posts WHERE blog_id = '$BLOG_ID';"
  echo ""
  echo "   -- Ver posts processados"
  echo "   SELECT * FROM posts WHERE blog_id = '$BLOG_ID' AND status = 'done';"
  echo ""
else
  echo -e "${RED}❌ Erro no sync${NC}"
  echo ""
  echo "Verifique:"
  echo "1. O workflow está ativo no n8n?"
  echo "2. O blog_id existe no Supabase?"
  echo "3. O user_id bate com o dono do blog?"
  echo "4. As variáveis de ambiente estão configuradas?"
  echo ""
fi

echo -e "${YELLOW}---${NC}"
echo ""
