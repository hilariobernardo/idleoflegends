# Cartas com efeitos próprios — v0.11

Documento histórico da v0.11. Os efeitos da tabela agora representam o nível 1; evolução, repetidas e salvamento foram atualizados nas [regras de níveis das cartas](CARTAS-NIVEIS.md). A devolução de IP por repetidas descrita abaixo foi substituída por subida de nível.

As cartas não concedem níveis nem pontos de habilidades. Cada uma modifica uma regra de economia ou combate por uma porcentagem. Os valores abaixo são iniciais para balanceamento.

| Carta | Raridade | Efeito ao equipar |
| --- | --- | --- |
| Lâmina de treino | Normal | +6% de dano contra jogadores |
| Moeda da rota | Normal | +8% de ouro na partida |
| Sentinela atenta | Normal | −5% de dano recebido pelos jogadores |
| Passos do estrategista | Rara | +10% de velocidade de movimento |
| Escudo do guardião | Rara | +12% de vida dos jogadores |
| Colheita dourada | Rara | +12% de XP ao terminar partidas |
| Fúria do duelista | Épica | +12% de velocidade de ataque |
| Olho do oráculo | Épica | −15% no tempo de renascimento |
| Plano de cerco | Épica | +20% de dano contra torres e nexo |
| Coroa do artífice | Lendária | +20% de ouro na partida e +10% de XP por partida |
| Tesouro do dragão | Lendária | +30% de dano contra Dragon e Baron |
| Lâmina da tempestade | Lendária | 20% de chance de crítico, causando +50% de dano |
| Coração do nexo | Mítica | +25% de vida do seu nexo |
| Visão do infinito | Mítica | +25% de XP por partida e −10% no tempo de renascimento |
| Comando soberano | Mítica | +20% de dano contra Dragon/Baron e +25% contra torres/nexo |

## Como os efeitos se combinam

Até três cartas diferentes podem ficar equipadas. Efeitos do mesmo tipo se somam: Moeda da rota + Coroa do artífice geram +28% de ouro. Tesouro do dragão + Comando soberano causam +50% de dano contra Dragon/Baron. Cópias repetidas não multiplicam efeitos.

Efeitos diferentes se aplicam separadamente. Por exemplo, +20% de dano contra estruturas com o bônus de +30% do Baron resulta em `1,20 × 1,30 = 1,56` do dano original. O crítico pode ocorrer contra jogadores, estruturas e monstros, mas dano específico contra jogadores não é aplicado a Dragon/Baron ou estruturas.

O ouro extra vale para farm das rotas, campos da selva e recompensas de abates/torres. A redução de dano recebido protege os jogadores de ataques inimigos e de torres; ela não protege as estruturas. A velocidade de movimento vale nas rotas, na selva e nos deslocamentos para objetivos. A velocidade de ataque reduz o intervalo entre ataques, sem acelerar o relógio.

A carta de vida do nexo aumenta sua resistência real; a barra e o desempate por tempo usam a proporção de vida restante, sem pontos extras apenas por começar com mais vida máxima.

## Recompensas e troca de equipamento

O bônus de XP vale para a recompensa de vitória **e** derrota, arredondada uma única vez para o inteiro mais próximo. Ele não altera XP/s dos estudos, IP nem pontos de elo. No modo de teste, o resultado mostra a recompensa, mas a carteira continua com XP ilimitado.

Todos os efeitos são copiados no início da partida, incluindo o bônus de XP. Equipar ou remover cartas durante o jogo só afeta a próxima partida. A coleção mostra o total dos efeitos para a próxima partida; o valor de XP na partida em andamento usa o equipamento com que ela começou.

## Coleção e compatibilidade

IDs, raridades, quantidades, cartas equipadas e garantia foram preservados. Saves v5 continuam válidos e passam a usar os novos efeitos automaticamente, sem perder a coleção; a estrutura de salvamento não mudou. Habilidades compradas mantêm exatamente seus níveis e custos.

A abertura continua custando 100 IP, com chances Normal 60%, Rara 25%, Épica 10%, Lendária 4% e Mítica 1%. São três cartas por raridade, com chances iguais dentro dela. Após nove aberturas sem épica ou superior, a próxima garante uma dessas raridades (10/15 épica, 4/15 lendária, 1/15 mítica). Repetidas devolvem 10/20/35/50/75 IP conforme a raridade.

As fontes de IP permanecem: novas divisões (+25), novo elo (+75 extras) e cada dez vitórias (+50). O modo de teste começa com 300 IP e não grava progresso. Anúncios e pagamentos seguem planejados.

As definições e descrições estão centralizadas em `game/scripts/card_catalog.gd`; a interface usa esses mesmos dados para evitar diferenças entre o texto e o efeito aplicado.
