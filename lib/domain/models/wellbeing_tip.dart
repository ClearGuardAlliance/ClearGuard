class WellbeingTip {
  const WellbeingTip({required this.title, required this.body});

  final String title;
  final String body;

  static const all = <WellbeingTip>[
    WellbeingTip(
      title: 'Surfe a onda do impulso',
      body: 'O impulso costuma atingir o pico e perder força sozinho em '
          '15 a 20 minutos. Em vez de lutar contra ele, observe sem agir '
          '— "surfar" a onda é uma técnica de terapia '
          'cognitivo-comportamental com respaldo em pesquisa para lidar '
          'com compulsões.',
    ),
    WellbeingTip(
      title: 'Confira o HALT antes de reagir',
      body: 'Fome, raiva, solidão e cansaço (HALT) são os quatro estados '
          'que mais antecedem uma recaída, segundo a literatura de '
          'prevenção de recaída. Antes de julgar o impulso, pergunte se '
          'algum desses quatro está pesando agora.',
    ),
    WellbeingTip(
      title: 'Mapeie seus gatilhos',
      body: 'Anote o horário, o lugar e o que você estava sentindo nas '
          'últimas vezes que quase abriu um app de risco. Reconhecer o '
          'padrão com antecedência é uma das técnicas centrais da TCC '
          'para reduzir recaídas.',
    ),
    WellbeingTip(
      title: 'Fale antes de precisar',
      body: 'Avisar seu parceiro de confiança quando o dia estiver difícil, '
          'antes de qualquer recaída, tira o peso da vergonha e fortalece '
          'a rede de apoio — a solidão é um dos gatilhos mais fortes.',
    ),
    WellbeingTip(
      title: 'Celular fora do quarto à noite',
      body: 'Momentos de tédio e cansaço à noite concentram boa parte das '
          'recaídas. Carregar o celular fora do quarto remove o acesso '
          'fácil justamente nesse horário.',
    ),
    WellbeingTip(
      title: 'Uma recaída não apaga o progresso',
      body: 'O objetivo é a tendência ao longo do tempo, não um histórico '
          'perfeito. Tratar um deslize como fracasso total costuma piorar '
          'a recaída; volte a focar no próximo momento em vez de desistir.',
    ),
  ];
}
