// Funções compartilhadas entre o painel e a página do cliente
(function () {
  const MESES = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
  const MESES_LONGOS = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];

  const TEMAS_PADRAO = [
    'Orçamento pessoal',
    'Metas e objetivos',
    'Gestão patrimonial',
    'Mapeamento de dívidas',
    'Gestão de riscos e proteção',
    'Análise de investimentos'
  ];

  function parseData(s) {
    if (!s) return null;
    const [y, m, d] = String(s).slice(0, 10).split('-').map(Number);
    if (!y || !m || !d) return null;
    return new Date(y, m - 1, d);
  }
  function iso(d) {
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  }
  function hojeISO() { return iso(new Date()); }
  function fmtCurta(s) {
    const d = parseData(s);
    if (!d) return 'Data a definir';
    return String(d.getDate()).padStart(2, '0') + ' ' + MESES[d.getMonth()] + ' ' + d.getFullYear();
  }
  function fmtLonga(s) {
    const d = parseData(s);
    if (!d) return 'data a definir';
    return d.getDate() + ' de ' + MESES_LONGOS[d.getMonth()] + ' de ' + d.getFullYear();
  }
  function fmtTimestamp(ts) {
    if (!ts) return '';
    const d = new Date(ts);
    if (isNaN(d)) return '';
    return d.getDate() + ' de ' + MESES_LONGOS[d.getMonth()] + ' de ' + d.getFullYear();
  }
  // Soma meses mantendo o dia (31/01 + 1 mês = 28/02)
  function addMeses(s, n) {
    const d = parseData(s);
    if (!d) return null;
    const dia = d.getDate();
    const alvo = new Date(d.getFullYear(), d.getMonth() + n, 1);
    const ultimo = new Date(alvo.getFullYear(), alvo.getMonth() + 1, 0).getDate();
    alvo.setDate(Math.min(dia, ultimo));
    return iso(alvo);
  }

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  // Texto livre -> parágrafos e listas (linhas começando com "-" ou "•" viram tópicos)
  function textoRico(s) {
    if (!s || !String(s).trim()) return '';
    const blocos = String(s).replace(/\r/g, '').split(/\n\s*\n/);
    return blocos.map(function (b) {
      const linhas = b.split('\n').map(function (l) { return l.trim(); }).filter(Boolean);
      if (!linhas.length) return '';
      const ehLista = linhas.every(function (l) { return /^[-•*–]\s*/.test(l); });
      if (ehLista) {
        return '<ul>' + linhas.map(function (l) { return '<li>' + esc(l.replace(/^[-•*–]\s*/, '')) + '</li>'; }).join('') + '</ul>';
      }
      return '<p>' + linhas.map(esc).join('<br>') + '</p>';
    }).join('');
  }

  // Combinados: cada linha é um item
  function itensLinha(s) {
    if (!s) return [];
    return String(s).replace(/\r/g, '').split('\n')
      .map(function (l) { return l.trim().replace(/^[-•*–]\s*/, ''); })
      .filter(Boolean);
  }

  function primeiroNome(nome) {
    return String(nome || '').trim().split(/\s+/)[0] || '';
  }

  function num2(n) { return String(n).padStart(2, '0'); }

  // Etapas do funil comercial
  const ETAPAS = [
    { id: 'novo', nome: 'Novo lead', dica: 'Chegou e ainda não teve contato' },
    { id: 'contato', nome: 'Em conversa', dica: 'Entendendo o momento e o motivo' },
    { id: 'diagnostico', nome: 'Diagnóstico', dica: 'Reunião de diagnóstico marcada' },
    { id: 'proposta', nome: 'Proposta enviada', dica: 'Aguardando decisão' },
    { id: 'followup', nome: 'Follow-up', dica: 'Retomar a conversa' },
    { id: 'fechado', nome: 'Fechado', dica: 'Virou cliente' },
    { id: 'perdido', nome: 'Perdido', dica: 'Não seguiu agora' }
  ];
  const ETAPAS_ABERTAS = ['novo', 'contato', 'diagnostico', 'proposta', 'followup'];
  function nomeEtapa(id) { const e = ETAPAS.find(function (x) { return x.id === id; }); return e ? e.nome : id; }

  function fmtMoeda(v) {
    if (v == null || v === '' || isNaN(Number(v))) return '';
    return Number(v).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: Number(v) % 1 ? 2 : 0 });
  }
  function diaSemana(s) {
    const d = parseData(s); if (!d) return '';
    return ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'][d.getDay()];
  }
  function diasEntre(aISO, bISO) {
    const a = parseData(aISO), b = parseData(bISO);
    if (!a || !b) return null;
    return Math.round((b - a) / 86400000);
  }
  // timestamptz -> {data:'YYYY-MM-DD', hora:'HH:MM'} no horário local
  function partesTs(ts) {
    if (!ts) return { data: null, hora: null };
    const d = new Date(ts); if (isNaN(d)) return { data: null, hora: null };
    return { data: iso(d), hora: num2(d.getHours()) + ':' + num2(d.getMinutes()) };
  }
  function tsParaInput(ts) { const p = partesTs(ts); return p.data ? p.data + 'T' + p.hora : ''; }
  function inputParaTs(v) { if (!v) return null; const d = new Date(v); return isNaN(d) ? null : d.toISOString(); }

  // Link "adicionar à Agenda do Google" (não precisa de login no painel)
  function linkGoogle(titulo, dataISO, hora, minutos, detalhes) {
    if (!dataISO) return '';
    const base = 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=' + encodeURIComponent(titulo);
    const d = dataISO.replace(/-/g, '');
    let datas;
    if (hora && /^\d{1,2}:\d{2}/.test(hora)) {
      const [h, m] = hora.split(':').map(Number);
      const ini = new Date(2000, 0, 1, h, m); const fim = new Date(ini.getTime() + (minutos || 60) * 60000);
      const f = function (x) { return num2(x.getHours()) + num2(x.getMinutes()) + '00'; };
      datas = d + 'T' + f(ini) + '/' + d + 'T' + f(fim);
    } else {
      const prox = parseData(dataISO); prox.setDate(prox.getDate() + 1);
      datas = d + '/' + iso(prox).replace(/-/g, '');
    }
    return base + '&dates=' + datas + '&ctz=America/Sao_Paulo' + (detalhes ? '&details=' + encodeURIComponent(detalhes) : '');
  }

  function linkWhats(numero, texto) {
    let n = String(numero || '').replace(/\D/g, '');
    if (!n) return '';
    if (n.length <= 11) n = '55' + n;
    return 'https://wa.me/' + n + (texto ? '?text=' + encodeURIComponent(texto) : '');
  }

  window.J = {
    TEMAS_PADRAO, ETAPAS, ETAPAS_ABERTAS, nomeEtapa, parseData, iso, hojeISO, fmtCurta, fmtLonga, fmtTimestamp,
    addMeses, esc, textoRico, itensLinha, primeiroNome, num2, fmtMoeda, diaSemana, diasEntre,
    partesTs, tsParaInput, inputParaTs, linkGoogle, linkWhats
  };
})();
