# 🔑 Configuração de Credenciais - n8n Vespuc.io

Guia passo a passo para configurar credenciais no seu n8n:
**https://n8n.hackpedia.com.br/**

---

## 📋 Índice

1. [Variáveis de Ambiente](#1-variáveis-de-ambiente-recomendado)
2. [Credenciais HTTP Header Auth](#2-credenciais-http-header-auth-alternativa)
3. [Onde Obter as Chaves](#3-onde-obter-as-chaves)
4. [Testar Configuração](#4-testar-configuração)
5. [Troubleshooting](#5-troubleshooting)

---

## 1. Variáveis de Ambiente (RECOMENDADO)

### Opção A: Configurar via Docker/Server

Se você tem acesso ao servidor onde o n8n está rodando:

```bash
# 1. Pare o n8n
docker stop n8n  # ou systemctl stop n8n

# 2. Configure as variáveis
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -e N8N_WEBHOOK_BASE_URL=https://n8n.hackpedia.com.br \
  -e SUPABASE_URL=https://sua-instancia.supabase.co \
  -e SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... \
  -e GEMINI_API_KEY=AIzaSy... \
  -v n8n-data:/home/node/.n8n \
  n8nio/n8n

# 3. Reinicie o n8n
docker restart n8n
```

### Opção B: Arquivo .env (se usa Docker Compose)

```bash
# 1. Crie o arquivo .env no servidor
cat > .env <<EOF
N8N_WEBHOOK_BASE_URL=https://n8n.hackpedia.com.br
SUPABASE_URL=https://sua-instancia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
GEMINI_API_KEY=AIzaSy...
EOF

# 2. Use no docker-compose.yml
services:
  n8n:
    image: n8nio/n8n
    env_file: .env
    ports:
      - 5678:5678
```

### Opção C: Via UI do n8n (Settings)

Se seu n8n permite, vá em:

1. **Settings** (ícone de engrenagem)
2. **Environments**
3. Adicione cada variável:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `GEMINI_API_KEY`
   - `N8N_WEBHOOK_BASE_URL`

⚠️ **Nota:** Nem todas as versões do n8n têm essa opção na UI.

---

## 2. Credenciais HTTP Header Auth (ALTERNATIVA)

Se você **não tem acesso ao servidor** ou prefere configurar pela UI:

### Passo 1: Criar Credencial para Supabase

1. Acesse: https://n8n.hackpedia.com.br
2. Clique em **"Credentials"** (sidebar esquerda)
3. Clique em **"Add Credential"**
4. Busque por **"HTTP Header Auth"**
5. Preencha:

```
Credential Name: Supabase API Key
Name: apikey
Value: sua-anon-key-do-supabase
```

**Exemplo:**
```
Name: apikey
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhtcGxxa3pjY3F2...
```

6. Clique em **"Create"**

### Passo 2: Configurar nos Workflows

Agora você precisa editar TODOS os nodes HTTP Request que chamam Supabase:

#### No workflow `Vespucio Sync Blog`:

1. Abra o workflow
2. Encontre o node **"Get Blog"**
3. Clique nele
4. Em **"Authentication"** selecione:
   - **Generic Credential Type**
   - Type: **HTTP Header Auth**
   - Credential: **Supabase API Key** (a que você criou)

5. **IMPORTANTE:** Remova o header `apikey` dos **Header Parameters** (ele virá da credencial)

6. Repita para TODOS os nodes HTTP Request que chamam Supabase:
   - `Get Blog`
   - `Set Status Syncing`
   - `Get Existing Posts`
   - `Insert New Posts`
   - `Get Pending Posts`
   - `Set Status OK`

#### No workflow `Vespucio Scrape Post`:

Repita o processo para:
   - `Set Processing`
   - `Update Post`
   - `Set Error Status`

### Passo 3: Configurar URL do Supabase

Como o `SUPABASE_URL` não pode vir de credencial, você tem 2 opções:

**Opção A:** Substituir `{{ $env.SUPABASE_URL }}` por URL hardcoded

Em cada node HTTP Request que chama Supabase, troque:

```
ANTES: {{ $env.SUPABASE_URL }}/rest/v1/blogs
DEPOIS: https://sua-instancia.supabase.co/rest/v1/blogs
```

**Opção B:** Usar variável de ambiente (requer acesso ao servidor)

Configure `SUPABASE_URL` no Docker/servidor como mostrado na seção 1.

### Passo 4: Configurar Gemini API Key

Para o Gemini, você precisa usar variável de ambiente OU hardcode:

**No node "Call Gemini AI":**

```
ANTES: {{ $env.GEMINI_API_KEY }}
DEPOIS: AIzaSy... (sua key real)
```

⚠️ **Segurança:** Hardcoded não é ideal, mas funciona para teste. O melhor é usar variáveis de ambiente.

---

## 3. Onde Obter as Chaves

### 🔷 Supabase

1. Acesse: https://supabase.com/dashboard
2. Selecione seu projeto
3. Vá em **Settings** → **API**
4. Copie:
   - **Project URL** → `SUPABASE_URL`
   - **Project API keys** → **anon/public** → `SUPABASE_ANON_KEY`

**Exemplo:**
```
SUPABASE_URL=https://xmplqkzccqvxpqzzwyqu.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBh...
```

⚠️ **Use a key ANON/PUBLIC**, não a service_role (que é secreta).

### 🔷 Gemini AI

1. Acesse: https://aistudio.google.com/apikey
2. Clique em **"Create API Key"**
3. Selecione um projeto do Google Cloud (ou crie um novo)
4. Copie a key gerada

**Exemplo:**
```
GEMINI_API_KEY=AIzaSyDXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

**Free tier:**
- 60 requests/min
- 1,500 requests/dia
- Grátis permanentemente

### 🔷 N8N Webhook Base URL

Use a URL do seu n8n:

```
N8N_WEBHOOK_BASE_URL=https://n8n.hackpedia.com.br
```

---

## 4. Testar Configuração

### Teste 1: Verificar Variáveis de Ambiente

1. Crie um workflow de teste
2. Adicione um node **Code**
3. Cole:

```javascript
return {
  supabase_url: $env.SUPABASE_URL,
  has_anon_key: !!$env.SUPABASE_ANON_KEY,
  has_gemini_key: !!$env.GEMINI_API_KEY,
  webhook_base: $env.N8N_WEBHOOK_BASE_URL
};
```

4. Execute manualmente
5. Verifique se retorna os valores

**Resultado esperado:**
```json
{
  "supabase_url": "https://xxx.supabase.co",
  "has_anon_key": true,
  "has_gemini_key": true,
  "webhook_base": "https://n8n.hackpedia.com.br"
}
```

### Teste 2: Testar Supabase

1. Crie um node **HTTP Request**
2. Configure:

```
Method: GET
URL: {{ $env.SUPABASE_URL }}/rest/v1/blogs?limit=1
Authentication: Generic Credential Type → HTTP Header Auth
Headers:
  - apikey: {{ $env.SUPABASE_ANON_KEY }} (se usar env)
  - Prefer: return=representation
```

3. Execute
4. Deve retornar array de blogs (ou vazio se não tem nada)

### Teste 3: Testar Gemini

1. Crie um node **HTTP Request**
2. Configure:

```
Method: POST
URL: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key={{ $env.GEMINI_API_KEY }}
Headers:
  - Content-Type: application/json
Body:
{
  "contents": [{
    "parts": [{
      "text": "Diga olá em uma palavra"
    }]
  }]
}
```

3. Execute
4. Deve retornar resposta da IA

### Teste 4: Testar Workflow Completo

```bash
# No terminal
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-123",
    "url": "https://techcrunch.com/"
  }'
```

Vá em **Executions** e veja se processou sem erros.

---

## 5. Troubleshooting

### ❌ "Cannot read property 'SUPABASE_URL' of undefined"

**Causa:** Variável de ambiente não configurada

**Solução:**
1. Configure no servidor/Docker
2. OU substitua `{{ $env.SUPABASE_URL }}` por URL hardcoded

### ❌ "Authentication required" do Supabase

**Causa:** API key não está sendo enviada

**Solução:**
1. Verifique se o header `apikey` está presente
2. Ou se a credencial HTTP Header Auth está configurada
3. Teste a key manualmente:

```bash
curl https://sua-instancia.supabase.co/rest/v1/blogs \
  -H "apikey: sua-anon-key" \
  -H "Authorization: Bearer sua-anon-key"
```

### ❌ "Invalid API key" do Gemini

**Causa:** API key inválida ou sem permissão

**Solução:**
1. Verifique se a key está correta
2. Ative a API no Google Cloud Console:
   - https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com
3. Gere uma nova key se necessário

### ❌ Workflow funciona em teste, mas não via webhook

**Causa:** `N8N_WEBHOOK_BASE_URL` incorreto

**Solução:**
```bash
# Configure corretamente
N8N_WEBHOOK_BASE_URL=https://n8n.hackpedia.com.br
```

### ❌ "Cheerio is not defined"

**Causa:** Dependência não instalada

**Solução:**
```bash
# No servidor
docker exec -it n8n npm install -g cheerio
docker restart n8n
```

---

## 🎯 Checklist Final

Antes de testar os workflows, verifique:

- [ ] `SUPABASE_URL` configurado (env ou hardcoded)
- [ ] `SUPABASE_ANON_KEY` configurado (env ou credencial)
- [ ] `GEMINI_API_KEY` configurado (env ou hardcoded)
- [ ] `N8N_WEBHOOK_BASE_URL` = `https://n8n.hackpedia.com.br`
- [ ] Credencial HTTP Header Auth criada (se não usar env)
- [ ] Todos os nodes HTTP Request configurados
- [ ] Workflows estão **Active**
- [ ] Cheerio instalado
- [ ] Tabelas criadas no Supabase

---

## 🚀 Método Rápido (Recomendado para Você)

Como você já tem n8n rodando, a forma mais rápida:

### 1. Configure Variáveis de Ambiente no Servidor

```bash
# SSH no servidor
ssh usuario@servidor

# Edite o docker-compose ou comando docker
# Adicione as env vars

# Reinicie
docker restart n8n
```

### 2. Atualize os Workflows

1. Abra cada workflow
2. Substitua `{{ $env.SUPABASE_URL }}` por `https://sua-instancia.supabase.co`
3. Mantenha `{{ $env.SUPABASE_ANON_KEY }}` e `{{ $env.GEMINI_API_KEY }}`
4. Salve

### 3. Ative e Teste

```bash
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{"id":"test","url":"https://techcrunch.com/"}'
```

---

## 📞 Precisa de Ajuda?

Se ainda tiver dúvidas:

1. Compartilhe prints da configuração (censure as keys!)
2. Compartilhe o erro exato que aparece
3. Veja os logs: `docker logs -f n8n`

**Webhook do seu n8n será:**
```
https://n8n.hackpedia.com.br/webhook/vespucio-sync-blog
https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post
```

Boa configuração! 🎉
