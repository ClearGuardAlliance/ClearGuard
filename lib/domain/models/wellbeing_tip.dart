class WellbeingTip {
  const WellbeingTip({required this.title, required this.body});

  final String title;
  final String body;

  static const all = <WellbeingTip>[
    WellbeingTip(
      title: 'Troque o gatilho pelo hábito',
      body: 'Tenha uma ação pronta para quando bater a vontade de abrir um '
          'app de risco: ligar para alguém, uma caminhada curta, água no '
          'rosto. O impulso passa em minutos.',
    ),
    WellbeingTip(
      title: 'Fale antes de precisar',
      body: 'Avisar seu parceiro de confiança quando o dia estiver difícil, '
          'antes de qualquer recaída, tira o peso da vergonha e fortalece '
          'a rede de apoio.',
    ),
    WellbeingTip(
      title: 'Espere 20 segundos',
      body: 'Antes de abrir qualquer app da lista de risco, respire fundo '
          'e conte até 20. A maior parte dos impulsos perde força nesse '
          'intervalo.',
    ),
    WellbeingTip(
      title: 'Celular fora do quarto à noite',
      body: 'Momentos de tédio e solidão à noite concentram boa parte das '
          'recaídas. Carregar o celular fora do quarto remove o acesso '
          'fácil justamente nesse horário.',
    ),
    WellbeingTip(
      title: 'Uma recaída não apaga o progresso',
      body: 'O objetivo é a tendência ao longo do tempo, não um histórico '
          'perfeito. Volte a focar no próximo momento em vez de desistir '
          'depois de um deslize.',
    ),
  ];
}
