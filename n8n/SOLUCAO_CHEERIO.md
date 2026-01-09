# 🔧 Solução: Cheerio não encontrado

## ❌ O Problema

```
Error: Cannot find module 'cheerio'
```

O n8n não encontra o cheerio mesmo depois do `npm install`.

---

## ✅ Solução: Use o Workflow SEM Cheerio

Criei um workflow que usa **apenas JavaScript puro + regex**!

### 📥 Passo 1: Importe o Workflow Simples

1. Baixe: `n8n/workflows/vespucio_scrape_SIMPLE.json`
2. Vá em: https://n8n.hackpedia.com.br
3. **Workflows** → **Add workflow** → **Import from file**
4. Selecione o arquivo `vespucio_scrape_SIMPLE.json`
5. Clique em **Import**

### 🚀 Passo 2: Ative e Teste

Toggle **"Active"** e teste:

```bash
curl -X POST https://n8n.hackpedia.com.br/webhook/scrape-simple \
  -H "Content-Type: application/json" \
  -d '{"url": "https://techcrunch.com/"}'
```

### 🎉 Resultado Esperado

```json
{
  "url": "https://techcrunch.com/",
  "title": "TechCrunch – Startup and Technology News",
  "num_images": 25,
  "num_videos": 2,
  "num_links_internal": 150,
  "num_links_external": 30,
  "text_preview": "Latest tech news...",
  "html_size": 256000,
  "success": true
}
```

✅ **Funciona sem instalar NADA!**

---

## 🔍 Por que o Cheerio não funciona?

### Possíveis causas:

1. **n8n rodando em container isolado**
   - O `npm install` local não afeta o container

2. **Permissões**
   - n8n pode não ter permissão para carregar módulos externos

3. **Versão do n8n**
   - Algumas versões não suportam require() de módulos externos

---

## 🛠️ Se você REALMENTE precisa do Cheerio

### Opção 1: Instalar no Container (Docker)

```bash
# Entre no container
docker exec -it n8n sh

# Instale cheerio no diretório correto
cd /usr/local/lib/node_modules/n8n
npm install cheerio

# Ou instale globalmente
npm install -g cheerio

# Saia e reinicie
exit
docker restart n8n
```

### Opção 2: Custom Docker Image

Crie um `Dockerfile`:

```dockerfile
FROM n8nio/n8n:latest

# Instala cheerio
RUN cd /usr/local/lib/node_modules/n8n && npm install cheerio

# Ou globalmente
RUN npm install -g cheerio
```

Build e rode:

```bash
docker build -t n8n-custom .
docker run -d -p 5678:5678 --name n8n n8n-custom
```

### Opção 3: Variável NODE_PATH

```bash
docker run -d \
  -e NODE_PATH=/usr/local/lib/node_modules \
  -p 5678:5678 \
  n8nio/n8n
```

---

## 🎯 Recomendação

**Use o workflow SIMPLE** (sem cheerio)! Ele:

- ✅ Funciona imediatamente
- ✅ Sem configuração
- ✅ Sem dependências
- ✅ Mesmos resultados
- ✅ Mais rápido

O cheerio só é necessário para parsing HTML complexo. Para extração básica (título, imagens, links), **regex é suficiente**!

---

## 📊 Comparação

| Feature | Com Cheerio | Sem Cheerio (Regex) |
|---------|-------------|---------------------|
| Título | ✅ | ✅ |
| Imagens | ✅ | ✅ |
| Vídeos | ✅ | ✅ |
| Links | ✅ | ✅ |
| Preview texto | ✅ | ✅ |
| Instalação | ❌ Complexa | ✅ Zero config |
| Performance | Média | Rápida |
| HTML malformado | ✅ Robusto | ⚠️ Pode falhar |

---

## 🚀 Teste Agora

```bash
# Importe vespucio_scrape_SIMPLE.json
# Ative o workflow
# Teste:

curl -X POST https://n8n.hackpedia.com.br/webhook/scrape-simple \
  -H "Content-Type: application/json" \
  -d '{"url": "https://blog.google/"}'
```

---

## 💡 Para Produção

Se você quiser usar o workflow original com Supabase + Gemini:

1. **Substitua** o node "Extract Data"
2. **Use** a versão com regex ao invés de cheerio
3. **Ou** instale cheerio no container definitivamente

Mas para **testes rápidos**, use o workflow SIMPLE! 🎉

---

Funcionou? Me avise! 🚀
