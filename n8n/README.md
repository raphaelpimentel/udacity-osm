# Vespuc.io - Workflows n8n

Este diretório contém os workflows n8n para o sistema Vespuc.io de descoberta e análise de blogs.

## 📦 Workflows

### 1. `vespucio_sync_blog.json`
**Função:** Descoberta de posts novos e sincronização de blog

**Pipeline:**
1. ✅ Recebe `blog_id` + `user_id` via webhook
2. ✅ Valida blog & ownership no Supabase
3. ✅ Seta `blogs.status = syncing`
4. ✅ Autodetecta sitemap (3 níveis):
   - `/sitemap_index.xml`
   - `/sitemap.xml`
   - `robots.txt` → `Sitemap:`
5. ✅ Extrai todos os URLs
6. ✅ Faz diff com posts existentes no Supabase
7. ✅ Insere novos posts como `pending`
8. ✅ Busca posts `pending` + `partial`
9. ✅ Para cada um: chama `vespucio_scrape_post`
10. ✅ No final: seta `blogs.status = ok`

**Webhook:** `POST /webhook/vespucio-sync-blog`

**Payload:**
```json
{
  "blog_id": "uuid-do-blog",
  "user_id": "uuid-do-usuario"
}
```

---

### 2. `vespucio_scrape_post.json`
**Função:** Scraping e extração de dados de 1 post

**Pipeline:**
1. ✅ Recebe `{id, url}` via webhook
2. ✅ Seta `posts.status = processing`
3. ✅ Baixa HTML (retry 3x)
4. ✅ Extrai dados via Cheerio:
   - ✅ `title` (meta tags + fallback)
   - ✅ `num_images` (count `<img>`)
   - ✅ `num_videos` (count `<video>` + YouTube/Vimeo iframes)
   - ✅ `num_links_internal` (links para mesma domain)
   - ✅ `num_links_external` (links externos)
5. ✅ Envia para Gemini AI:
   - ✅ `category` (technology, travel, food, etc)
   - ✅ `summary` (1-2 frases)
6. ✅ Atualiza post no Supabase
7. ✅ Seta `status = done` | `partial` | `error`

**Webhook:** `POST /webhook/vespucio-scrape-post`

**Payload:**
```json
{
  "id": "uuid-do-post",
  "url": "https://blog.com/post-url"
}
```

---

## 🚀 Como Importar

### 1. Acesse o n8n

```bash
# Se estiver rodando localmente
npx n8n
# ou
docker run -it --rm --name n8n -p 5678:5678 n8nio/n8n
```

Acesse: http://localhost:5678

### 2. Importe os Workflows

1. Clique em **"Workflows"** → **"Add workflow"** → **"Import from file"**
2. Selecione o arquivo:
   - `n8n/workflows/vespucio_sync_blog.json`
   - `n8n/workflows/vespucio_scrape_post.json`
3. Repita para o segundo workflow

### 3. Configure as Credenciais

Você precisa configurar as seguintes variáveis de ambiente no n8n:

```bash
# Supabase
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-anon-key-publica

# Gemini AI
GEMINI_API_KEY=sua-api-key-do-gemini

# n8n (para chamar webhooks internos)
N8N_WEBHOOK_BASE_URL=https://seu-n8n.com
```

#### Como configurar no n8n:

**Opção A: Variáveis de ambiente (recomendado)**
```bash
# Docker
docker run -it --rm \
  -p 5678:5678 \
  -e SUPABASE_URL=https://xxx.supabase.co \
  -e SUPABASE_ANON_KEY=xxx \
  -e GEMINI_API_KEY=xxx \
  -e N8N_WEBHOOK_BASE_URL=https://n8n.yourdomain.com \
  n8nio/n8n

# Local
export SUPABASE_URL=https://xxx.supabase.co
export SUPABASE_ANON_KEY=xxx
export GEMINI_API_KEY=xxx
export N8N_WEBHOOK_BASE_URL=http://localhost:5678
npx n8n
```

**Opção B: Credentials no n8n**

1. Vá em **Settings** → **Credentials**
2. Crie uma credential **"HTTP Header Auth"** para Supabase:
   - Name: `Supabase API`
   - Header Name: `apikey`
   - Value: `sua-anon-key`

### 4. Ative os Workflows

1. Abra cada workflow
2. Clique em **"Active"** (toggle no topo direito)
3. Verifique que o webhook foi criado:
   - `/webhook/vespucio-sync-blog`
   - `/webhook/vespucio-scrape-post`

---

## 🧪 Como Testar

### Teste 1: Sync Blog

```bash
curl -X POST http://localhost:5678/webhook/vespucio-sync-blog \
  -H "Content-Type: application/json" \
  -d '{
    "blog_id": "uuid-do-blog",
    "user_id": "uuid-do-usuario"
  }'
```

**Resposta esperada:**
```json
{
  "success": true,
  "blog_id": "uuid-do-blog",
  "status": "ok",
  "message": "Sync concluído com sucesso"
}
```

### Teste 2: Scrape Post

```bash
curl -X POST http://localhost:5678/webhook/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{
    "id": "uuid-do-post",
    "url": "https://blog.example.com/post"
  }'
```

**Resposta esperada:**
```json
{
  "success": true,
  "post_id": "uuid-do-post",
  "status": "done",
  "title": "Título do Post"
}
```

---

## 🔍 Troubleshooting

### ❌ Erro: "Blog não encontrado ou não pertence ao usuário"

**Causa:** O `blog_id` + `user_id` não existem no Supabase ou não batem.

**Solução:**
1. Verifique se o blog existe: `SELECT * FROM blogs WHERE id = 'uuid'`
2. Verifique ownership: `SELECT * FROM blogs WHERE id = 'uuid' AND user_id = 'uuid'`

### ❌ Erro: "Sitemap não encontrado"

**Causa:** O blog não tem sitemap nos 3 caminhos padrão.

**Solução:**
1. Verifique manualmente:
   - `https://blog.com/sitemap_index.xml`
   - `https://blog.com/sitemap.xml`
   - `https://blog.com/robots.txt`
2. Se o sitemap estiver em outro path, adicione lógica custom no workflow

### ❌ Erro: "Gemini API failed"

**Causa:** API key inválida ou quota excedida.

**Solução:**
1. Verifique a key: https://aistudio.google.com/app/apikey
2. Verifique quota: https://console.cloud.google.com/apis/api/generativelanguage.googleapis.com/quotas
3. Se falhar, o workflow marca o post como `partial` e continua

### ❌ Erro: "Cheerio not found"

**Causa:** Cheerio não está instalado no n8n.

**Solução:**
```bash
# Se usar Docker, crie uma imagem custom
FROM n8nio/n8n
RUN npm install cheerio -g

# Se usar local
npm install cheerio -g
```

### ❌ Erro: "CORS" ao fazer scraping

**Causa:** Alguns sites bloqueiam requests sem User-Agent.

**Solução:**
1. Adicione header `User-Agent` no node "Fetch HTML":
```json
{
  "User-Agent": "Mozilla/5.0 (compatible; VespucBot/1.0)"
}
```

---

## 📊 Monitoramento

### Ver execuções

1. Vá em **Executions** no n8n
2. Filtre por workflow
3. Clique em uma execução para ver logs detalhados

### Métricas importantes

- ✅ Taxa de sucesso de sync (blogs.status = ok)
- ✅ Taxa de posts scraped (posts.status = done)
- ✅ Tempo médio de scraping
- ✅ Erros por tipo (CORS, timeout, 404, etc)

---

## 🔄 Melhorias Futuras

- [ ] Retry exponencial backoff para scraping
- [ ] Rate limiting (respeitar robots.txt)
- [ ] Cache de sitemaps (evitar refetch)
- [ ] Suporte para JavaScript-heavy sites (Puppeteer)
- [ ] Anti-bot detection (rotação de User-Agent)
- [ ] Webhook de callback (notificar quando sync terminar)
- [ ] Dead letter queue (posts que sempre falham)

---

## 📞 Suporte

Problemas? Abra uma issue no GitHub ou consulte a documentação do Vespuc.io.
