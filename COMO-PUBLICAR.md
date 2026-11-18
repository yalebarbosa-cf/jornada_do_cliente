# Jornada do Cliente · como colocar no ar

## O que tem aqui
- `site/index.html`: o seu painel (login, lista de clientes, cadastro e edição)
- `site/cliente.html`: a página que o cliente vê pelo link
- `site/config.js`: onde entram os dados do Supabase e o seu WhatsApp
- `supabase.sql`: a estrutura do banco

## 1. Supabase (uns 10 minutos)
1. Crie um projeto novo no Supabase (região São Paulo, se aparecer).
2. Vá em **SQL Editor > New query**, cole todo o conteúdo de `supabase.sql` e clique em **Run**.
3. Vá em **Authentication > Users > Add user > Create new user**, coloque o seu e-mail e uma senha forte. É com ele que você entra no painel.
4. Vá em **Authentication > Sign In / Providers > Email** e desligue **Allow new users to sign up**. Assim ninguém mais cria conta.
5. Vá em **Project Settings > API** e copie a **Project URL** e a chave **anon public**.

## 2. config.js
Abra `site/config.js` e cole a URL e a chave anon entre as aspas. Em `WHATSAPP_YALI`, coloque o seu número só com números (ex.: 5581999999999).

## 3. GitHub Pages
1. Crie um repositório novo e público, por exemplo `JornadaCliente`.
2. Envie todos os arquivos da pasta `site` (Add file > Upload files).
3. Em **Settings > Pages**, escolha a branch `main` e a pasta `/ (root)`.
4. O painel fica em `https://yalebarbosa-cf.github.io/JornadaCliente/`.

## Como usar no dia a dia
- **Novo cliente:** nome, data do 1º encontro e número de encontros. As datas mensais e os temas da proposta são criados automaticamente.
- **Depois de cada encontro:** ligue "Realizado", escreva o que decidiram e os combinados (um por linha) e clique em **Salvar**.
- **Enviar o link:** botão "Enviar no WhatsApp", que já leva uma mensagem pronta.
- **Encerrar acesso:** desligue "Link ativo". "Gerar novo link" invalida o antigo.

## Privacidade
Cada link tem um código aleatório impossível de adivinhar, e a página do cliente só recebe o nome, os encontros e os três textos. E-mail, WhatsApp e anotações internas nunca saem do painel. Mesmo assim, evite colocar números de conta ou documentos nos textos.
