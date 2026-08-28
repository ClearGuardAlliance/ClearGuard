class WellbeingTip {
  const WellbeingTip({required this.title, required this.body});

  final String title;
  final String body;

  static WellbeingTip forDay(DateTime date) {
    final startOfYear = DateTime(date.year);
    final dayOfYear = date.difference(startOfYear).inDays;
    return all[dayOfYear % all.length];
  }

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
    WellbeingTip(
      title: 'Tenha um plano se-então',
      body: 'Decida agora: "se eu sentir vontade de abrir [app], então vou '
          '[ação específica]". Pesquisas sobre planos se-então mostram que '
          'essa associação prévia entre gatilho e resposta funciona melhor '
          'do que confiar só na força de vontade na hora.',
    ),
    WellbeingTip(
      title: 'Mexa o corpo por 10 minutos',
      body: 'Exercício de intensidade moderada a alta reduz a intensidade '
          'do impulso quase na mesma hora, segundo estudos com diferentes '
          'tipos de compulsão. Uma caminhada rápida ou um treino curto '
          'já ajuda.',
    ),
    WellbeingTip(
      title: 'Trate a culpa com gentileza, não com punição',
      body: 'Vergonha ("eu sou o problema") está ligada a mais recaída do '
          'que autocompaixão ("eu escorreguei, e daí?"). Reconhecer o '
          'deslize sem se atacar é o que a pesquisa associa a uma '
          'recuperação mais estável.',
    ),
  ];
}
