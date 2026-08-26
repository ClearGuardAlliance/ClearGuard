<!-- Languages: [English](README.md) | Português | [עברית](README.he.md) | [Русский](README.ru.md) | [中文](README.zh.md) | [日本語](README.ja.md) | [العربية](README.ar.md) -->

# ClearGuard

ClearGuard é um app Android que bloqueia pornografia por DNS local e, como reforço, por leitura de texto na tela. A diferença central é que desativar a proteção nunca é instantâneo: todo pedido de enfraquecer a proteção passa por um tempo de espera e avisa um parceiro de confiança antes de valer.

## Como funciona

O bloqueio principal roda numa VPN local que filtra as consultas de DNS pela lista de domínios bloqueados. Um serviço de acessibilidade lê o texto visível na tela como camada extra, para pegar conteúdo que passou do filtro de DNS. Qualquer ação que enfraqueça a proteção, como desativar o bloqueio ou remover um domínio, cria um pedido pendente com PIN, prazo e notificação ao parceiro. Fortalecer a proteção é sempre imediato.

## Arquitetura

O código Flutter fica em `lib`, dividido em `data` (serviços e repositórios), `domain` (modelos e regras de negócio) e `ui` (telas e view models). O código nativo Android fica em `native_android`, com o serviço de VPN, o monitor de tela e as instruções para integrar num projeto Flutter gerado.

## Limitações

O bloqueio por DNS não impede acesso direto por IP. A permissão de VPN e o serviço de acessibilidade podem ser revogados pelo dono do aparelho nas configurações do sistema, e nenhum app fora de MDM consegue impedir isso. Nada aqui foi compilado ainda, pois esta máquina não tem Flutter nem Android SDK instalados.

## Rodando

```bash
flutter pub get
flutter test
```

Para a parte Android, siga `native_android/README.md`.
