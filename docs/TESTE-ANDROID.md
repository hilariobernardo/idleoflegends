# Teste inicial de balanceamento e Android

Em 30/10/2026, os testes automatizados de fluxo, progressão, economia, migração e simulação passaram. São testes de regras e não substituem uma sessão com jogadores.

Em 100 sementes determinísticas, o time inicial ganhou 53 partidas contra rivais de nível 0. Contra rivais de nível 4, ganhou 0; com todas as habilidades no nível 8, ganhou 100. Esses cenários extremos indicam que é preciso medir níveis intermediários e observar a experiência real antes de alterar os valores.

No início, o estudo gratuito gera 1 XP/s: sem investir nem jogar, a primeira melhoria de vídeos (100 XP) leva 100 segundos, e 10.000 XP levam 2h46min40s de geração efetiva. O limite de duas horas por ausência impede receber tudo em uma única ausência longa. Partidas, compras e tempo aberto mudam esses tempos; a Ranked também exige Barro IV. Em condições ideais, subir de Sal IV a Barro IV exige 16 vitórias líquidas, ou seja, 16 vitórias sem derrotas. Isso não é uma estimativa de tempo real de desbloqueio.

Ao testar no aparelho, observar legibilidade, botões, rolagem, retorno após deixar o aplicativo em segundo plano, tempo até a primeira melhoria, ritmo de vitórias e derrotas, e quanto demora para chegar à Ranked. O jogo em segundo plano não completa partidas offline; apenas os estudos geram XP, até duas horas.

Medição adicional com 20 sementes por cenário, contra adversários de nível 4 e todas as habilidades do jogador no mesmo nível: nível 0: 0/20 vitórias; nível 2: 0/20; nível 4: 10/20; nível 6: 20/20; nível 8: 20/20. São amostras pequenas, úteis para identificar a transição, não probabilidades definitivas. Reproduza com `--headless --path game --script res://tests/measure_balance.gd`.
