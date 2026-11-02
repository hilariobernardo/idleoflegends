# Teste inicial de balanceamento e Android

## Efeitos percentuais — v0.11 — 02/11/2026

Dois testes aprovados com Godot 4.7.2: `test_cards.gd` passou com 2.076 verificações, incluindo todos os efeitos, combinações, aplicação em combate, ouro, XP, persistência e ausência de níveis extras. `test_mobile_ui.gd` passou com quatro tamanhos de tela, descrições, equipamento, objetivos, velocidade, reinício e recompensa de XP fixada pelo equipamento inicial, mesmo após trocar cartas.

APK: [Nexo-Idle-0.11.apk](https://github.com/hilariobernardo/idleoflegends/raw/refs/heads/work/builds/Nexo-Idle-0.11.apk), versão 0.11/código 11. Assinatura v2/v3 e alinhamento de 16 KB verificados. SHA-256: `c796cbb59252f83f0697ba078151335975e73da034605db95181dcd27ff63323`.

O ambiente foi renovado e a chave temporária da v0.10 não estava disponível. Esta compilação usa uma nova assinatura de depuração, mantida fora do repositório; o Android pode exigir desinstalar a versão anterior, apagando dados locais. O modo de teste continua sem salvar sessões. Não houve instalação em aparelho físico; os testes de interface foram executados sem janela gráfica.

As regras e a tabela das 15 cartas estão em [CARTAS-v011.md](CARTAS-v011.md). AGENTS.md e README foram atualizados no mesmo commit.

## Entrega v0.10 pelo GitHub — 01/11/2026

Integradas as cartas/IP e grades de evolução ao branch `work`, preservando Dragon/Baron, posições dos jogadores, mapa e velocidade 2×. Os dois testes foram executados novamente com Godot 4.7.2: `test_cards.gd` passou com 2.035 verificações; `test_mobile_ui.gd` passou com os quatro tamanhos de tela, painel inferior, compras, cartas, bônus, objetivos, velocidade e reinício. A verificação de arraste considera o espaço de rolagem realmente disponível na tela.

APK: [Nexo-Idle-0.10.apk](https://github.com/hilariobernardo/idleoflegends/raw/refs/heads/work/builds/Nexo-Idle-0.10.apk), versão 0.10/código 10. Assinatura v2/v3 e alinhamento de 16 KB verificados. O APK usa a mesma chave de depuração da compilação local v0.9; a assinatura do APK mais antigo do GitHub pode ser diferente. Não houve instalação em aparelho físico.

SHA-256: `8ba6d19c6684470879d03daeb7f44fe33d18ee4ec4aac9ffb7b765d0ab2086e5`.

Por solicitação do usuário e seguindo a entrega já existente no repositório, o APK versionado e seu checksum são publicados em `builds/`, com download direto pelo GitHub. Ferramentas, caches e chaves continuam excluídos do Git. AGENTS.md e README registram esta orientação e o histórico das mudanças.

## Atualização v0.9 — 01/11/2026

Dois testes executados com Godot **4.7.2.stable.official.ed1daf0bf** e aprovados:

1. `test_cards.gd`: 2.035 verificações de recompensas de IP, proteção contra promoção repetida, abertura, devolução de repetidas, garantia de raridade, equipamentos, persistência, migração v4, reversão em falhas de gravação e reinício do modo de teste. O teste identificou e motivou a normalização dos números JSON da coleção e dos recordes de elo para inteiros ao carregar.
2. `test_mobile_ui.gd`: arrastar e tocar, seleção obrigatória de modo, quatro tamanhos de tela (540×960, 540×1200, 540×1260 e 768×1024), limites horizontais dos botões, grupos de upgrades em duas colunas, abertura/equipamento de cartas, bônus na próxima partida e reinício.

Comandos, a partir da raiz do repositório e com Godot 4.7.2 no PATH:

```sh
godot --headless --path game --script res://tests/test_cards.gd
godot --headless --path game --script res://tests/test_mobile_ui.gd
godot --headless --path game --export-debug Android builds/Nexo-Idle-v0.9.apk
```

Na exportação, use um caminho absoluto para o APK caso sua instalação resolva o caminho relativo a partir de `game/`. Configure previamente o SDK Android, Java e a chave de depuração no editor.

APK gerado: `builds/Nexo-Idle-v0.9.apk`, pacote `com.nexoidle.prototipo`, versão 0.9/código 9, Android mínimo API 24, alvo API 36, arquiteturas ARMv7 e ARM64. Assinatura v2/v3 e alinhamento de 16 KB verificados. Scripts de cartas e navegação incluídos; arquivos de testes excluídos. SDK, engine, chaves, logs e APK permanecem fora do Git.

SHA-256: `222dfb54786158549da5acd2733a228415277e40042b5e673bc08feeacab744b`.

A chave de depuração foi criada neste ambiente, pois a assinatura do APK anterior não está disponível. Atualizar sobre uma instalação com outra assinatura pode exigir a remoção do aplicativo antigo, apagando seus dados locais. Não houve instalação em aparelho físico ou emulador; os testes da interface foram executados sem janela gráfica.

## Histórico v0.4

Em 30/10/2026, os testes automatizados de fluxo, progressão, economia, migração e simulação passaram. São testes de regras e não substituem uma sessão com jogadores.

Em 100 sementes determinísticas, o time inicial ganhou 53 partidas contra rivais de nível 0. Contra rivais de nível 4, ganhou 0; com todas as habilidades no nível 8, ganhou 100. Esses cenários extremos indicam que é preciso medir níveis intermediários e observar a experiência real antes de alterar os valores.

No início, o estudo gratuito gera 1 XP/s: sem investir nem jogar, a primeira melhoria de vídeos (100 XP) leva 100 segundos, e 10.000 XP levam 2h46min40s de geração efetiva. O limite de duas horas por ausência impede receber tudo em uma única ausência longa. Partidas, compras e tempo aberto mudam esses tempos; a Ranked também exige Barro IV. Em condições ideais, subir de Sal IV a Barro IV exige 16 vitórias líquidas, ou seja, 16 vitórias sem derrotas. Isso não é uma estimativa de tempo real de desbloqueio.

Ao testar no aparelho, observar legibilidade, botões, rolagem, retorno após deixar o aplicativo em segundo plano, tempo até a primeira melhoria, ritmo de vitórias e derrotas, e quanto demora para chegar à Ranked. O jogo em segundo plano não completa partidas offline; apenas os estudos geram XP, até duas horas.

Medição adicional com 20 sementes por cenário, contra adversários de nível 4 e todas as habilidades do jogador no mesmo nível: nível 0: 0/20 vitórias; nível 2: 0/20; nível 4: 10/20; nível 6: 20/20; nível 8: 20/20. São amostras pequenas, úteis para identificar a transição, não probabilidades definitivas. Reproduza com `--headless --path game --script res://tests/measure_balance.gd`.
