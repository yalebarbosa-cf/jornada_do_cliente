# Painel Yale Barbosa

Painel da empresa: **Início**, **Agenda**, **Funil** (CRM) e **Clientes**, com a jornada de cada cliente e um link exclusivo para compartilhar.

- `docs/index.html`: o painel (só você, com login)
- `docs/cliente.html`: a página da jornada que o cliente vê pelo link
- `docs/config.js`: endereço e chave pública do Supabase (já preenchidos)
- `supabase.sql`: estrutura completa do banco (já aplicada no projeto "Jornada do Cliente")

## Colocar no ar (uma vez só)
1. No GitHub, abra este repositório > **Settings > General**, desça até **Danger Zone > Change visibility** e deixe **Public**.
   O GitHub Pages gratuito só publica repositórios públicos. Nenhum dado de cliente fica no código: tudo está no Supabase, protegido por login.
2. **Settings > Pages**: em *Source* escolha **Deploy from a branch**, branch **main**, pasta **/docs**, e salve.
3. Em 1 a 2 minutos o painel fica em: `https://yalebarbosa-cf.github.io/jornada_do_cliente/`

## Supabase
- Entre com o mesmo e-mail e senha que você criou em Authentication > Users.
- Recomendado: **Authentication > Sign In / Providers > Email**, desligar **Allow new users to sign up**.
- No plano gratuito, o Supabase pausa o projeto depois de 7 dias sem uso. Abrir o painel algumas vezes por semana evita isso.

## Configurar dentro do painel (ícone de engrenagem)
- **E-mail da Agenda do Google**: a sua agenda aparece na aba Agenda (é preciso estar conectada à conta Google no navegador).
- **WhatsApp**: vira o botão "Falar pelo WhatsApp" na página dos clientes.

## Formulário de diagnóstico → Funil
O banco tem a função `novo_lead`, que qualquer formulário pode chamar para criar um lead na etapa "Novo lead".
Para a página `diagnostico.html` das advogadas enviar para o funil (além da Karppa), adicione esta chamada no envio do formulário:

```js
fetch('https://byttjbmmifhqmcgtoadz.supabase.co/rest/v1/rpc/novo_lead', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    apikey: 'CHAVE_ANON_DO_CONFIG_JS',
    Authorization: 'Bearer CHAVE_ANON_DO_CONFIG_JS'
  },
  body: JSON.stringify({
    p_nome: nome, p_whatsapp: whatsapp, p_email: email,
    p_origem: 'Página das advogadas', p_profissao: 'Advogada',
    p_renda: renda, p_momento: momento, p_quando: quandoComecar
  })
});
```
