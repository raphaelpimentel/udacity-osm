# 🐛 Troubleshooting: "Invalid input syntax for type uuid"

## ❌ O Erro

```
Bad request - please check your parameters
Invalid input syntax for type uuid: "test-123"
```

**Causa:** O Supabase espera um UUID válido (ex: `550e8400-e29b-41d4-a716-446655440000`), mas você enviou `"test-123"`.

---

## ✅ Solução 1: Testar SEM Supabase (Apenas Scraping)

Se você quer apenas testar a **extração de dados** (scraping), sem salvar no banco:

### Passo 1: Desabilite os nodes do Supabase

1. Abra o workflow **"Vespucio Scrape Post"**
2. Clique no node **"Set Processing"**
3. Desabilite o node:
   - Clique com botão direito → **Disable**
   - OU clique no node → toggle "Disabled" no painel lateral

4. Repita para:
   - **"Update Post"**
   - **"Set Error Status"**

5. Conecte diretamente:
   - **"Extract Data"** → **"Check Content"** → **"Call Gemini AI"** → **"Merge AI Data"** → **"Success Response"**

### Passo 2: Teste novamente

```bash
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-123",
    "url": "https://techcrunch.com/"
  }'
```

Agora você verá os dados extraídos sem erros! 🎉

---

## ✅ Solução 2: Usar UUID Válido (Com Supabase)

Se você quer testar o fluxo completo com Supabase:

### Passo 1: Crie um post de teste no Supabase

```sql
-- Execute no SQL Editor do Supabase

-- Insira um post de teste
INSERT INTO posts (blog_id, user_id, url, status)
VALUES (
  'SEU-BLOG-UUID-AQUI',  -- UUID de um blog existente
  'SEU-USER-UUID-AQUI',  -- UUID do seu usuário
  'https://techcrunch.com/',
  'pending'
)
RETURNING id;
```

**Como pegar os UUIDs:**

```sql
-- Ver blogs existentes
SELECT id, base_url FROM blogs LIMIT 1;

-- Ver usuários
SELECT id, email FROM auth.users LIMIT 1;
```

### Passo 2: Copie o UUID retornado

O INSERT retornará algo como:
```
id: 550e8400-e29b-41d4-a716-446655440000
```

### Passo 3: Teste com UUID real

```bash
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "url": "https://techcrunch.com/"
  }'
```

---

## ✅ Solução 3: Gerar UUID Dinamicamente (Para Testes)

Se você não quer criar no banco primeiro, modifique o workflow temporariamente:

### Passo 1: Adicione node para gerar UUID

1. No workflow, adicione um node **"Code"** após **"Validate Input"**
2. Cole:

```javascript
const crypto = require('crypto');

// Gera UUID v4
function uuidv4() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

// Se o ID não for UUID válido, gera um novo
const inputId = $input.item.json.post_id;
const isValidUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(inputId);

return {
  post_id: isValidUUID ? inputId : uuidv4(),
  post_url: $input.item.json.post_url
};
```

3. Conecte: **Validate Input** → **Code** → **Set Processing**

### Passo 2: Teste

```bash
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{
    "id": "qualquer-coisa",
    "url": "https://techcrunch.com/"
  }'
```

Agora vai gerar um UUID válido automaticamente!

---

## ✅ Solução 4: Teste o Workflow de Sync (Recomendado)

O workflow correto para usar é o **"Vespucio Sync Blog"**, que descobre os posts e gera UUIDs automaticamente:

### Passo 1: Crie um blog no Supabase

```sql
INSERT INTO blogs (user_id, base_url, status)
VALUES (
  (SELECT id FROM auth.users LIMIT 1),
  'https://blog.google',
  'new'
)
RETURNING id, user_id;
```

### Passo 2: Teste o sync

```bash
# Use os UUIDs retornados acima
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-sync-blog \
  -H "Content-Type: application/json" \
  -d '{
    "blog_id": "UUID-DO-BLOG",
    "user_id": "UUID-DO-USER"
  }'
```

Isso vai:
1. ✅ Descobrir sitemap
2. ✅ Criar posts com UUIDs válidos
3. ✅ Fazer scraping automaticamente

---

## 🎯 Método Mais Rápido (Para Você Agora)

**Recomendo a Solução 1** se você só quer ver o scraping funcionando:

1. Desabilite os 3 nodes do Supabase
2. Teste com qualquer ID
3. Veja os dados extraídos em **Executions**

**Exemplo:**

```bash
curl -X POST https://n8n.hackpedia.com.br/webhook/vespucio-scrape-post \
  -H "Content-Type: application/json" \
  -d '{
    "id": "ignorado",
    "url": "https://techcrunch.com/"
  }'
```

Vá em **Executions** e veja o node **"Extract Data"** para ver os dados extraídos! 🎉

---

## 🔍 Como Verificar o Resultado

Após executar com sucesso, você verá:

```json
{
  "title": "TechCrunch | Startup and Technology News",
  "num_images": 25,
  "num_videos": 3,
  "num_links_internal": 150,
  "num_links_external": 45,
  "category": "technology",
  "summary": "Tech news and startup coverage"
}
```

---

## 📊 Qual Solução Usar?

| Objetivo | Solução | Dificuldade |
|----------|---------|-------------|
| Ver scraping funcionando | Solução 1 | ⭐ Fácil |
| Teste completo com banco | Solução 2 | ⭐⭐ Médio |
| Testes automatizados | Solução 3 | ⭐⭐⭐ Avançado |
| Uso real do sistema | Solução 4 | ⭐⭐ Médio |

---

## 💡 Dica

Para **produção**, use sempre o workflow **"Vespucio Sync Blog"**, que gerencia tudo automaticamente. O **"Vespucio Scrape Post"** é chamado internamente pelo Sync.

---

Qual solução você quer tentar primeiro? Me avise se precisar de ajuda! 🚀
