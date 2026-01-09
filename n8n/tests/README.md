# 🧪 Scripts de Teste - Vespuc.io

Scripts prontos para testar os workflows n8n.

---

## 🚀 Início Rápido (1 comando)

```bash
# Suba o n8n com Docker (interativo)
./setup_n8n.sh
```

Depois acesse **http://localhost:5678** e importe os workflows.

---

## 📋 Scripts Disponíveis

### 1. `setup_n8n.sh` - Setup completo do n8n

**O que faz:**
- ✅ Verifica Docker
- ✅ Limpa containers antigos
- ✅ Cria volume persistente
- ✅ Configura variáveis (interativo)
- ✅ Sobe n8n na porta 5678
- ✅ Instala dependências (cheerio)

**Como usar:**
```bash
./setup_n8n.sh
```

**Interativo:** Vai pedir Supabase URL, API Keys (opcional - pode usar mock)

---

### 2. `test_scraper.sh` - Testa scraping de posts

**O que faz:**
- ✅ Testa extração de dados de blogs reais
- ✅ Valida parsing HTML
- ✅ Testa categorização via IA
- ✅ Inclui teste de erro (URL inválida)

**Como usar:**
```bash
# Com n8n local
./test_scraper.sh

# Com n8n remoto
N8N_URL=https://seu-n8n.com ./test_scraper.sh
```

**Blogs testados:**
1. TechCrunch (tecnologia)
2. Nomadic Matt (viagem)
3. Akita on Rails (tech BR)
4. URL inválida (teste de erro)

**Não precisa de Supabase configurado!**

---

### 3. `test_sync_blog.sh` - Testa sincronização completa

**O que faz:**
- ✅ Valida blog no Supabase
- ✅ Descobre sitemap
- ✅ Insere posts novos
- ✅ Chama scraper para cada post

**ATENÇÃO:** Requer Supabase configurado!

**Como usar:**

1. Configure as variáveis:
```bash
export BLOG_ID='uuid-do-seu-blog'
export USER_ID='uuid-do-seu-usuario'
```

2. Execute:
```bash
./test_sync_blog.sh
```

**Ou inline:**
```bash
BLOG_ID='xxx' USER_ID='yyy' ./test_sync_blog.sh
```

---

## 🔧 Pré-requisitos

### Para `setup_n8n.sh`:
- Docker instalado
- Porta 5678 livre

### Para `test_scraper.sh`:
- n8n rodando (localhost:5678 ou remoto)
- Workflow `Vespucio Scrape Post` importado e ativo
- `jq` instalado (opcional, para formatar JSON):
  ```bash
  # Mac
  brew install jq

  # Ubuntu/Debian
  sudo apt install jq
  ```

### Para `test_sync_blog.sh`:
- Tudo do `test_scraper.sh` +
- Workflow `Vespucio Sync Blog` importado e ativo
- Supabase configurado (tabelas criadas)
- Blog cadastrado no Supabase
- Variáveis `BLOG_ID` e `USER_ID`

---

## 📊 Como Interpretar Resultados

### ✅ Sucesso no Scraper:

```json
{
  "success": true,
  "post_id": "test-123",
  "status": "done",
  "title": "Título extraído do post"
}
```

**Verifique no n8n:**
- Executions → última execução verde
- Node `Extract Data` → veja métricas (images, videos, links)
- Node `Call Gemini AI` → veja categoria e resumo

### ✅ Sucesso no Sync:

```json
{
  "success": true,
  "blog_id": "uuid-do-blog",
  "status": "ok",
  "message": "Sync concluído com sucesso"
}
```

**Verifique no Supabase:**
```sql
-- Status do blog
SELECT status, last_synced_at FROM blogs WHERE id = 'uuid';

-- Posts descobertos
SELECT COUNT(*) FROM posts WHERE blog_id = 'uuid';

-- Posts processados
SELECT COUNT(*) FROM posts WHERE blog_id = 'uuid' AND status = 'done';
```

### ❌ Erro comum - Cheerio:

```
Error: cheerio is not defined
```

**Solução:**
```bash
docker exec -it n8n-vespuc npm install -g cheerio
docker restart n8n-vespuc
```

### ❌ Erro comum - Webhook não encontrado:

```
404 Not Found
```

**Solução:**
1. Certifique-se que o workflow está **Active** (toggle verde)
2. Use a URL exata mostrada no node Webhook
3. Reinicie o workflow (desativa + ativa)

### ❌ Erro comum - Supabase:

```
"Blog não encontrado ou não pertence ao usuário"
```

**Solução:**
```sql
-- Verifique se o blog existe
SELECT * FROM blogs WHERE id = 'seu-blog-id';

-- Verifique ownership
SELECT * FROM blogs WHERE id = 'blog-id' AND user_id = 'user-id';
```

---

## 🔍 Debug

### Ver logs do n8n:

```bash
docker logs -f n8n-vespuc
```

### Ver execuções no n8n UI:

1. Acesse: http://localhost:5678
2. Sidebar → **Executions**
3. Clique na execução
4. Veja cada node e seus dados

### Testar manualmente com curl:

```bash
# Teste simples
curl -X POST http://localhost:5678/webhook/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{"id":"test","url":"https://example.com"}'

# Com output formatado
curl -X POST http://localhost:5678/webhook/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{"id":"test","url":"https://example.com"}' | jq '.'
```

---

## 🎯 Fluxo Recomendado de Teste

### 1. Teste Rápido (sem Supabase):

```bash
# 1. Suba n8n
./setup_n8n.sh

# 2. Importe workflows na UI
# http://localhost:5678

# 3. Teste scraper
./test_scraper.sh
```

### 2. Teste Completo (com Supabase):

```bash
# 1. Configure Supabase (SQL no QUICKSTART.md)

# 2. Crie um blog de teste
# INSERT INTO blogs...

# 3. Configure variáveis
export BLOG_ID='uuid'
export USER_ID='uuid'

# 4. Teste sync completo
./test_sync_blog.sh

# 5. Acompanhe no Supabase
# SELECT * FROM posts WHERE blog_id = 'uuid';
```

---

## 🧹 Limpeza

### Parar n8n:
```bash
docker stop n8n-vespuc
```

### Remover tudo:
```bash
docker stop n8n-vespuc
docker rm n8n-vespuc
docker volume rm n8n-vespuc-data
```

### Manter dados, apenas reiniciar:
```bash
docker restart n8n-vespuc
```

---

## 📞 Troubleshooting

**Problema:** Docker não encontrado
**Solução:** Instale Docker → https://docs.docker.com/get-docker/

**Problema:** Porta 5678 ocupada
**Solução:**
```bash
# Ver o que está usando
lsof -i :5678

# Parar processo ou use outra porta
docker run -p 9999:5678 ...
```

**Problema:** Scripts não executam (permission denied)
**Solução:**
```bash
chmod +x *.sh
```

**Problema:** jq não encontrado
**Solução:**
```bash
brew install jq  # Mac
sudo apt install jq  # Linux
```

---

## 🎉 Pronto!

Agora você pode testar os workflows localmente antes de usar em produção!

Dúvidas? Veja o `QUICKSTART.md` na pasta raiz de `n8n/`.
