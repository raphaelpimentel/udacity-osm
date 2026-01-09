# ⚡ Configuração Rápida - 5 Minutos

Guia visual para configurar credenciais no **seu n8n**:
👉 https://n8n.hackpedia.com.br/

---

## 🎯 O Que Você Precisa

Antes de começar, pegue estas 3 chaves:

### 1. Supabase (2 valores)

Acesse: https://supabase.com/dashboard → seu projeto → **Settings** → **API**

```
✅ Project URL (ex: https://abc123.supabase.co)
✅ anon/public key (começa com eyJ...)
```

### 2. Gemini AI (1 valor)

Acesse: https://aistudio.google.com/apikey → **Create API Key**

```
✅ API Key (começa com AIzaSy...)
```

---

## 🚀 Método 1: Via UI (SEM acesso ao servidor)

### Passo 1: Criar Credencial HTTP Header Auth

1. Acesse: https://n8n.hackpedia.com.br
2. Clique em **"Credentials"** (barra lateral esquerda, ícone de chave 🔑)
3. Clique em **"Add Credential"** (botão azul no topo)
4. Na busca, digite: **"HTTP Header Auth"**
5. Clique em **"HTTP Header Auth"**
6. Preencha:

```
Credential Name: Supabase API
Name: apikey
Value: [COLE SUA SUPABASE ANON KEY AQUI]
```

7. Clique em **"Save"**

### Passo 2: Editar Workflow `Vespucio Sync Blog`

1. Vá em **Workflows** → abra **"Vespucio Sync Blog"**

2. **Clique no node "Get Blog"** (segundo node)
   - Scroll até **"URL"**
   - Substitua `{{ $env.SUPABASE_URL }}` por sua URL:
     ```
     https://sua-instancia.supabase.co/rest/v1/blogs
     ```
   - Scroll até **"Authentication"**
   - Selecione: **Generic Credential Type**
   - Generic Auth Type: **HTTP Header Auth**
   - Credential: **Supabase API**
   - **IMPORTANTE:** Remova o header `apikey` de "Header Parameters" (já vem da credencial)
   - Clique em **"Save"** (ou feche o painel)

3. **Repita para TODOS os nodes HTTP Request que chamam Supabase:**
   - `Set Status Syncing`
   - `Get Existing Posts`
   - `Insert New Posts`
   - `Get Pending Posts`
   - `Set Status OK`

   Para cada um:
   - Substitua `{{ $env.SUPABASE_URL }}` pela URL real
   - Configure Authentication → HTTP Header Auth → Supabase API
   - Remova header `apikey` duplicado

4. **Configurar Gemini (se quiser IA):**

   Não tem node de Gemini neste workflow, pule para o próximo.

5. **Configurar N8N_WEBHOOK_BASE_URL:**

   - No node **"Call Scraper"**
   - Substitua `{{ $env.N8N_WEBHOOK_BASE_URL }}` por:
     ```
     https://n8n.hackpedia.com.br
     ```

6. Clique em **"Save"** (botão no topo direito)

### Passo 3: Editar Workflow `Vespucio Scrape Post`

1. Vá em **Workflows** → abra **"Vespucio Scrape Post"**

2. **Edite os nodes de Supabase:**
   - `Set Processing`
   - `Update Post`
   - `Set Error Status`

   Para cada um:
   - Substitua `{{ $env.SUPABASE_URL }}` pela URL real
   - Configure Authentication → HTTP Header Auth → Supabase API
   - Remova header `apikey` duplicado

3. **Configure Gemini no node "Call Gemini AI":**

   - Clique no node **"Call Gemini AI"**
   - Na URL, substitua `{{ $env.GEMINI_API_KEY }}` por sua key:
     ```
     https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=AIzaSy...
     ```

4. Clique em **"Save"**

### Passo 4: Ativar os Workflows

1. Abra **"Vespucio Sync Blog"**
2. Toggle **"Active"** (canto superior direito, botão switch)
3. Deve ficar verde ✅
4. Repita para **"Vespucio Scrape Post"**

### Passo 5: Testar

```bash
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-123",
    "url": "https://techcrunch.com/"
  }'
```

Vá em **Executions** (barra lateral) e veja se apareceu execução verde ✅

---

## 🔧 Método 2: Via Variáveis de Ambiente (COM acesso ao servidor)

### Se você tem SSH no servidor:

```bash
# 1. SSH no servidor
ssh usuario@seu-servidor

# 2. Edite o arquivo .env ou docker-compose
nano .env

# 3. Adicione:
SUPABASE_URL=https://sua-instancia.supabase.co
SUPABASE_ANON_KEY=eyJ...
GEMINI_API_KEY=AIzaSy...
N8N_WEBHOOK_BASE_URL=https://n8n.hackpedia.com.br

# 4. Reinicie n8n
docker restart n8n
# ou
docker-compose restart
```

**Vantagem:** Não precisa editar os workflows! Tudo vem das variáveis de ambiente.

---

## ✅ Checklist Rápido

Depois de configurar, verifique:

- [ ] Credencial "Supabase API" criada ✅
- [ ] TODOS os nodes HTTP Request configurados com a credencial
- [ ] URLs substituídas (sem `{{ $env.SUPABASE_URL }}`)
- [ ] Gemini API key configurada (sem `{{ $env.GEMINI_API_KEY }}`)
- [ ] Workflows salvos ✅
- [ ] Workflows ativos (toggle verde) ✅
- [ ] Testou via curl ✅
- [ ] Execução apareceu em verde ✅

---

## 🎬 Resumo Visual

```
┌─────────────────────────────────────┐
│ 1. Credentials → Add Credential     │
│    → HTTP Header Auth               │
│    → Name: apikey                   │
│    → Value: sua-anon-key            │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ 2. Workflow → Node HTTP Request     │
│    → URL: https://xxx.supabase.co   │
│    → Auth: HTTP Header Auth         │
│    → Credential: Supabase API       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ 3. Repetir para TODOS os nodes      │
│    que chamam Supabase              │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ 4. Save → Active → Test             │
└─────────────────────────────────────┘
```

---

## 🐛 Erros Comuns

### ❌ "Cannot read property of undefined"

Você esqueceu de substituir `{{ $env.SUPABASE_URL }}`.

**Fix:** Troque por `https://sua-instancia.supabase.co`

### ❌ "Authentication required"

Header `apikey` não está sendo enviado.

**Fix:** Verifique se a credencial está selecionada no node.

### ❌ "Invalid API key" (Gemini)

Key inválida ou API não ativada.

**Fix:**
1. Verifique a key em https://aistudio.google.com/apikey
2. Ative a API em https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com

### ❌ Workflow não executa via webhook

Workflow não está ativo.

**Fix:** Toggle "Active" no canto superior direito.

---

## 🎯 Exemplo Completo de um Node Configurado

**Node: Get Blog**

```yaml
URL: https://xmplqkzccqvx.supabase.co/rest/v1/blogs

Authentication:
  ✅ Generic Credential Type
  Type: HTTP Header Auth
  Credential: Supabase API

Query Parameters:
  - id: eq.{{ $json.blog_id }}
  - user_id: eq.{{ $json.user_id }}
  - select: id,user_id,base_url,status

Headers:
  - Prefer: return=representation
  ❌ NÃO coloque apikey aqui (já vem da credencial)
```

---

## 🚀 Tudo Pronto!

Agora seus workflows estão configurados e prontos para usar!

**Próximo passo:** Configure o Supabase (tabelas) - veja `QUICKSTART.md` seção 3.

**Webhooks finais:**
```
https://n8n.hackpedia.com.br/webhook/vespucio-sync-blog
https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post
```

Precisa de ajuda? Me mande o erro específico! 🙌
