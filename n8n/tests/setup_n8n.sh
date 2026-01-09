#!/bin/bash

# Script para setup rápido do n8n com Docker
# Instala tudo que é necessário para testar os workflows

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Setup n8n para Vespuc.io${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. Verifica se Docker está instalado
echo -e "${YELLOW}📦 Verificando Docker...${NC}"
if ! command -v docker &> /dev/null; then
  echo -e "${RED}❌ Docker não encontrado${NC}"
  echo ""
  echo "Instale o Docker:"
  echo "  - Mac: https://docs.docker.com/desktop/install/mac-install/"
  echo "  - Linux: https://docs.docker.com/engine/install/"
  echo "  - Windows: https://docs.docker.com/desktop/install/windows-install/"
  echo ""
  exit 1
fi
echo -e "${GREEN}✅ Docker encontrado${NC}"
echo ""

# 2. Para container antigo se existir
echo -e "${YELLOW}🧹 Limpando containers antigos...${NC}"
docker stop n8n-vespuc 2>/dev/null || true
docker rm n8n-vespuc 2>/dev/null || true
echo -e "${GREEN}✅ Limpeza concluída${NC}"
echo ""

# 3. Cria volume para persistência
echo -e "${YELLOW}💾 Criando volume para dados...${NC}"
docker volume create n8n-vespuc-data 2>/dev/null || true
echo -e "${GREEN}✅ Volume criado${NC}"
echo ""

# 4. Lê variáveis de ambiente (opcional)
echo -e "${YELLOW}🔑 Configuração de variáveis de ambiente${NC}"
echo ""
echo "Deixe em branco para usar valores MOCK (apenas para teste de scraping)"
echo ""

read -p "SUPABASE_URL (Enter para mock): " SUPABASE_URL
SUPABASE_URL=${SUPABASE_URL:-https://mock.supabase.co}

read -p "SUPABASE_ANON_KEY (Enter para mock): " SUPABASE_ANON_KEY
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-mock-key-123}

read -p "GEMINI_API_KEY (Enter para mock): " GEMINI_API_KEY
GEMINI_API_KEY=${GEMINI_API_KEY:-mock-gemini-key}

echo ""
echo -e "${GREEN}✅ Variáveis configuradas${NC}"
echo ""

# 5. Sobe o container
echo -e "${YELLOW}🐳 Subindo n8n...${NC}"
docker run -d \
  --name n8n-vespuc \
  -p 5678:5678 \
  -e N8N_WEBHOOK_BASE_URL=http://localhost:5678 \
  -e EXECUTIONS_PROCESS=main \
  -e SUPABASE_URL="$SUPABASE_URL" \
  -e SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  -e GEMINI_API_KEY="$GEMINI_API_KEY" \
  -v n8n-vespuc-data:/home/node/.n8n \
  n8nio/n8n

echo -e "${GREEN}✅ n8n iniciado!${NC}"
echo ""

# 6. Aguarda n8n ficar pronto
echo -e "${YELLOW}⏳ Aguardando n8n inicializar...${NC}"
sleep 10

# Verifica se está rodando
if docker ps | grep -q n8n-vespuc; then
  echo -e "${GREEN}✅ n8n está rodando!${NC}"
else
  echo -e "${RED}❌ Erro ao iniciar n8n${NC}"
  echo ""
  echo "Logs:"
  docker logs n8n-vespuc
  exit 1
fi
echo ""

# 7. Instala dependências no container
echo -e "${YELLOW}📦 Instalando dependências (cheerio)...${NC}"
docker exec n8n-vespuc npm install -g cheerio 2>/dev/null || echo "⚠️  Cheerio já instalado ou falhou (será instalado automaticamente pelo n8n)"
echo -e "${GREEN}✅ Dependências instaladas${NC}"
echo ""

# 8. Instruções finais
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Setup concluído!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}🌐 Acesse: http://localhost:5678${NC}"
echo ""
echo -e "${YELLOW}📝 Próximos passos:${NC}"
echo ""
echo "1. Abra http://localhost:5678 no navegador"
echo "2. Crie uma conta (primeira vez)"
echo "3. Importe os workflows:"
echo "   - Workflows → Add workflow → Import from file"
echo "   - Selecione: n8n/workflows/vespucio_sync_blog.json"
echo "   - Selecione: n8n/workflows/vespucio_scrape_post.json"
echo "4. Ative os workflows (toggle 'Active')"
echo "5. Teste com os scripts:"
echo ""
echo "   chmod +x n8n/tests/*.sh"
echo "   ./n8n/tests/test_scraper.sh"
echo ""
echo -e "${YELLOW}🔧 Comandos úteis:${NC}"
echo ""
echo "  # Ver logs"
echo "  docker logs -f n8n-vespuc"
echo ""
echo "  # Parar n8n"
echo "  docker stop n8n-vespuc"
echo ""
echo "  # Reiniciar n8n"
echo "  docker restart n8n-vespuc"
echo ""
echo "  # Remover tudo"
echo "  docker stop n8n-vespuc && docker rm n8n-vespuc"
echo "  docker volume rm n8n-vespuc-data"
echo ""
echo -e "${GREEN}🎉 Bom teste!${NC}"
echo ""
