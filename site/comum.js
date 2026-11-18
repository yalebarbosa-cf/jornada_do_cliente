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

  window.J = {
    TEMAS_PADRAO, parseData, iso, hojeISO, fmtCurta, fmtLonga, fmtTimestamp,
    addMeses, esc, textoRico, itensLinha, primeiroNome, num2
  };
})();
