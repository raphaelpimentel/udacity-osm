# 🚀 Quickstart - Testando os Workflows Vespuc.io

Guia rápido para testar os workflows n8n **AGORA**, mesmo sem Supabase configurado.

---

## Opção 1: Teste Rápido com Docker (RECOMENDADO)

### 1. Suba o n8n

```bash
# Clone o repo (se ainda não tem)
git clone https://github.com/raphaelpimentel/udacity-osm.git
cd udacity-osm

# Suba n8n com Docker
docker run -d \
  --name n8n-vespuc \
  -p 5678:5678 \
  -e N8N_WEBHOOK_BASE_URL=http://localhost:5678 \
  -e EXECUTIONS_PROCESS=main \
  -v $(pwd)/n8n/workflows:/workflows \
  n8nio/n8n
```

Acesse: **http://localhost:5678**

### 2. Configure conta inicial

- Email: `seu-email@example.com`
- Password: qualquer senha forte

### 3. Importe os workflows

**Via UI:**
1. Clique em **"Workflows"** (sidebar)
2. **"Add workflow"** → **"Import from file"**
3. Selecione `n8n/workflows/vespucio_sync_blog.json`
4. Repita para `vespucio_scrape_post.json`

**Via linha de comando (alternativa):**
```bash
# Copie os workflows para o volume do Docker
docker cp n8n/workflows/vespucio_sync_blog.json n8n-vespuc:/home/node/.n8n/workflows/
docker cp n8n/workflows/vespucio_scrape_post.json n8n-vespuc:/home/node/.n8n/workflows/
docker restart n8n-vespuc
```

### 4. Instale dependências necessárias

```bash
# Entre no container
docker exec -it n8n-vespuc sh

# Instale cheerio (necessário para parsing HTML)
npm install -g cheerio

# Saia
exit
```

### 5. Configure variáveis de ambiente (MOCK para teste)

**Abra cada workflow e adicione as variáveis temporariamente:**

1. Abra `Vespucio Sync Blog`
2. Clique em qualquer node HTTP Request
3. Vá em **Settings** → **Environment Variables**
4. Adicione:

```bash
# MOCK - para testes sem Supabase real
SUPABASE_URL=https://mock.supabase.co
SUPABASE_ANON_KEY=mock-key-123
GEMINI_API_KEY=mock-gemini-key
N8N_WEBHOOK_BASE_URL=http://localhost:5678
```

**OU configure via Docker:**
```bash
# Pare o container
docker stop n8n-vespuc
docker rm n8n-vespuc

# Suba com variáveis
docker run -d \
  --name n8n-vespuc \
  -p 5678:5678 \
  -e N8N_WEBHOOK_BASE_URL=http://localhost:5678 \
  -e SUPABASE_URL=https://sua-instancia.supabase.co \
  -e SUPABASE_ANON_KEY=sua-chave-aqui \
  -e GEMINI_API_KEY=sua-chave-gemini \
  -v $(pwd)/n8n/workflows:/workflows \
  n8nio/n8n
```

### 6. Ative os workflows

1. Abra `Vespucio Sync Blog`
2. Toggle **"Active"** (canto superior direito)
3. Copie a URL do webhook (ex: `http://localhost:5678/webhook/vespucio-sync-blog`)
4. Repita para `Vespucio Scrape Post`

### 7. Teste o Scraper (sem Supabase)

**Teste apenas a parte de scraping (mais fácil):**

```bash
# Teste em um blog público real
curl -X POST http://localhost:5678/webhook-test/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-123",
    "url": "https://blog.google/technology/"
  }'
```

**Resultado esperado:**
- ✅ Extração de title, images, videos, links
- ✅ Categoria + resumo via IA (se Gemini configurado)
- ❌ Erro ao salvar no Supabase (esperado se não configurou)

### 8. Ver resultado

1. Vá em **Executions** no n8n
2. Clique na última execução
3. Veja os dados extraídos em cada node:
   - `Extract Data` → métricas SEO
   - `Call Gemini AI` → categoria e resumo
   - `Update Post` → vai falhar se Supabase não configurado (OK para teste)

---

## Opção 2: Teste com n8n local (NPM)

### 1. Instale n8n

```bash
npm install -g n8n
```

### 2. Configure variáveis

```bash
export N8N_WEBHOOK_BASE_URL=http://localhost:5678
export SUPABASE_URL=https://mock.supabase.co
export SUPABASE_ANON_KEY=mock-key
export GEMINI_API_KEY=sua-chave-ou-mock
```

### 3. Suba n8n

```bash
n8n start
```

Acesse: **http://localhost:5678**

### 4. Siga passos 2-8 da Opção 1

---

## Opção 3: Teste COMPLETO com Supabase

### Pré-requisitos:
1. Conta no Supabase (grátis): https://supabase.com
2. API Key do Gemini (grátis): https://aistudio.google.com/apikey

### 1. Configure Supabase

```sql
-- Crie as tabelas (execute no SQL Editor do Supabase)

-- Users (já existe via Supabase Auth)

-- Blogs
CREATE TABLE blogs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  base_url TEXT NOT NULL,
  status TEXT DEFAULT 'new' CHECK (status IN ('new', 'syncing', 'ok', 'error')),
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Posts
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blog_id UUID REFERENCES blogs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  url TEXT NOT NULL UNIQUE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'partial', 'done', 'error')),
  title TEXT,
  category TEXT,
  num_images INT DEFAULT 0,
  num_videos INT DEFAULT 0,
  num_links_internal INT DEFAULT 0,
  num_links_external INT DEFAULT 0,
  summary TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_posts_blog_status ON posts(blog_id, status);
CREATE INDEX idx_blogs_user ON blogs(user_id);

-- RLS Policies (básico)
ALTER TABLE blogs ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their blogs" ON blogs
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their posts" ON posts
  FOR ALL USING (auth.uid() = user_id);
```

### 2. Insira um blog de teste

```sql
-- Substitua USER_ID pelo seu UUID do Supabase Auth
INSERT INTO blogs (user_id, base_url, status)
VALUES (
  'SEU-USER-UUID-AQUI',
  'https://blog.google',
  'new'
)
RETURNING id;

-- Copie o UUID retornado (será usado no teste)
```

### 3. Configure as variáveis no n8n

```bash
# Pegue do Supabase (Settings → API)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Pegue do Google AI Studio
GEMINI_API_KEY=AIzaSy...
```

### 4. Teste o fluxo completo

```bash
# Substitua pelos UUIDs reais
curl -X POST http://localhost:5678/webhook/vespucio-sync-blog \
  -H "Content-Type: application/json" \
  -d '{
    "blog_id": "uuid-do-blog-inserido",
    "user_id": "seu-user-uuid"
  }'
```

**O que vai acontecer:**
1. ✅ Valida blog no Supabase
2. ✅ Seta status `syncing`
3. ✅ Descobre sitemap de `https://blog.google`
4. ✅ Extrai URLs
5. ✅ Insere novos posts como `pending`
6. ✅ Para cada post:
   - Faz scraping
   - Extrai métricas
   - Chama Gemini
   - Atualiza Supabase
7. ✅ Seta status `ok`

### 5. Verifique no Supabase

```sql
-- Ver o blog
SELECT * FROM blogs;

-- Ver posts descobertos
SELECT id, url, status, title, category FROM posts;

-- Ver posts processados
SELECT * FROM posts WHERE status = 'done';
```

---

## 🧪 Teste Rápido SEM Supabase

Se você quer testar APENAS a lógica de scraping:

### 1. Modifique o workflow temporariamente

Abra `Vespucio Scrape Post` no n8n e:

1. **Desative** os nodes de Supabase:
   - `Set Processing`
   - `Update Post`
2. **Conecte** `Extract Data` direto para `Success Response`

### 2. Teste com webhook de teste

```bash
curl -X POST http://localhost:5678/webhook-test/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-123",
    "url": "https://techcrunch.com/2024/01/01/example-post/"
  }'
```

### 3. Veja o resultado no node `Extract Data`

Você verá:
```json
{
  "title": "Título extraído",
  "num_images": 5,
  "num_videos": 1,
  "num_links_internal": 12,
  "num_links_external": 3,
  "category": "technology",
  "summary": "Resumo do post"
}
```

---

## 🔍 Troubleshooting

### ❌ "Webhook não encontrado"

**Solução:**
1. Certifique-se que o workflow está **Active**
2. Use a URL exata mostrada no node Webhook
3. Use `/webhook/` (não `/webhook-test/`)

### ❌ "Cheerio is not defined"

**Solução:**
```bash
# No Docker
docker exec -it n8n-vespuc npm install -g cheerio

# Local
npm install -g cheerio
```

### ❌ "Gemini API error"

**Solução:**
- Teste sem IA primeiro (vai marcar como `partial`)
- Ou pegue uma key grátis: https://aistudio.google.com/apikey

### ❌ "CORS error" ao fazer scraping

**Solução:**
Adicione User-Agent no node `Fetch HTML`:
```json
{
  "User-Agent": "Mozilla/5.0 (compatible; VespucBot/1.0)"
}
```

---

## 🎯 Próximos passos

Após validar que funciona:

1. ✅ Configure Supabase de verdade
2. ✅ Configure Gemini API
3. ✅ Teste com seus blogs reais
4. ✅ Deploy n8n em produção (Render, Railway, etc)
5. ✅ Configure webhooks na UI do Vespuc.io

---

## 📊 Como validar sucesso

**Sync Blog:**
- ✅ Status muda de `new` → `syncing` → `ok`
- ✅ Posts são inseridos na tabela
- ✅ Scraping é chamado para cada post

**Scrape Post:**
- ✅ Extração de title, images, videos, links
- ✅ Categoria + resumo via IA
- ✅ Status muda para `done`

**No n8n:**
- ✅ Execuções aparecem em verde
- ✅ Cada node mostra dados processados
- ✅ Sem erros vermelhos

---

Precisa de ajuda? Veja os logs detalhados em **Executions** no n8n!
