# 🚀 Teste Rápido - 2 Minutos

Vamos testar o scraping **SEM Supabase** primeiro, só para ver funcionar!

---

## 📝 Passo a Passo

### 1️⃣ Acesse seu n8n

👉 https://n8n.hackpedia.com.br/workflow/2cTMBLnc1tqywDLX

### 2️⃣ Modifique o workflow "Vespucio Scrape Post"

**Vamos desabilitar os nodes do Supabase:**

1. Clique no node **"Set Processing"** (3º node)
2. No painel lateral direito, procure **"Disabled"**
3. Toggle para **ON** (desabilitar)
4. Feche o painel

Repita para:
- ✅ **"Set Processing"**
- ✅ **"Update Post"** (penúltimo node antes do Success Response)
- ✅ **"Set Error Status"**

### 3️⃣ Ajuste as conexões

Conecte os nodes ativos diretamente:

**Nova conexão:**
```
Webhook Trigger
    ↓
Validate Input
    ↓
Fetch HTML  ←─────────┐
    ↓                  │
Extract Data           │
    ↓                  │
Check Content          │
    ↓        ↓         │
Call Gemini  Set Partial
    ↓        ↓         │
Merge AI Data          │
    ↓                  │
Merge Results          │
    ↓                  │
Success Response       │
                       │
[Prepare Error]────────┘
    ↓
Error Response
```

**Ou mais simples:**

Apenas conecte **"Merge Results"** direto ao **"Success Response"** (pule o "Update Post").

### 4️⃣ Salve

Clique em **"Save"** (botão no topo direito)

### 5️⃣ Ative

Toggle **"Active"** (canto superior direito)

### 6️⃣ Teste!

```bash
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test",
    "url": "https://techcrunch.com/"
  }'
```

### 7️⃣ Veja o resultado

1. Vá em **Executions** (sidebar esquerda)
2. Clique na última execução
3. Veja o node **"Extract Data"** → verá:

```json
{
  "title": "TechCrunch - Startup News",
  "num_images": 25,
  "num_videos": 2,
  "num_links_internal": 150,
  "num_links_external": 30
}
```

---

## ✅ Funcionou?

**SIM** → Agora vamos configurar o Supabase!

**NÃO** → Me mande um print do erro

---

## 🎯 Opção Ainda Mais Rápida - RECOMENDADO ⭐

**Use o workflow de teste pronto!**

### 1. Baixe o arquivo

📥 `n8n/workflows/vespucio_scrape_post_TESTE.json`

### 2. Importe no n8n

1. Acesse: https://n8n.hackpedia.com.br
2. **Workflows** → **Add workflow** → **Import from file**
3. Selecione o arquivo `vespucio_scrape_post_TESTE.json`
4. Clique em **Import**

### 3. Ative

Toggle **"Active"** (canto superior direito)

### 4. Teste!

```bash
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post-test \
  -H "Content-Type: application/json" \
  -d '{"url": "https://techcrunch.com/"}'
```

### 5. Veja o resultado

**Resposta esperada:**

```json
{
  "url": "https://techcrunch.com/",
  "title": "TechCrunch – Startup and Technology News",
  "num_images": 25,
  "num_videos": 2,
  "num_links_internal": 150,
  "num_links_external": 30,
  "text_preview": "Latest tech news about startups...",
  "html_size": 256000,
  "success": true
}
```

✅ **Pronto! Funciona sem configurar NADA!**

---

## 🧪 Teste com Outros Sites

```bash
# Blog de viagem
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post-test \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.nomadicmatt.com/"}'

# Blog BR
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post-test \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.akitaonrails.com/"}'

# Wikipedia
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post-test \
  -H "Content-Type: application/json" \
  -d '{"url": "https://en.wikipedia.org/wiki/Web_scraping"}'
```
