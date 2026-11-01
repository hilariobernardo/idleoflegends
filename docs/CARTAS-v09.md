# Cartas e evolução — v0.9

Na entrega v0.10, estas regras foram integradas às mudanças do branch `work`: Dragon/Baron e velocidade 2× foram preservados, e os dois grupos de evolução também aparecem no painel com rolagem abaixo do mapa. O download atualizado está no README.

A navegação agora tem Partida, Evolução, Cartas e Modos. Evolução reúne dois grupos: habilidades de combate e estudos que produzem XP. Cada grupo usa uma grade de dois blocos por fileira, com rolagem vertical comum, nível, efeito e compra no próprio bloco.

## Idle Points (IP)

IP é separado do XP e continua limitado mesmo com XP ilimitado no modo de teste. Valores iniciais para ajustar o ritmo:

- +25 IP ao atingir uma divisão inédita em cada modo. Na Ranked, para em Mestre, onde terminam as subdivisões.
- +75 IP extras ao atingir um elo inédito (por exemplo, Sal → Barro), incluindo Mestre, Grão-Mestre e Challenger.
- +50 IP a cada 10 vitórias acumuladas, somando Normal e Ranked. Derrotas não reiniciam o contador.
- Cair e voltar à mesma divisão ou elo não paga novamente. O maior total de pontos alcançado fica registrado por modo.
- Estudos não geram IP. Não há conversão de XP em IP.

No modo de teste, cada sessão começa com 300 IP. Recomeçar limpa cartas, equipamentos e garantias, restaura 300 IP e mantém o comportamento anterior de XP ilimitado e ausência de gravação. Fora do modo de teste, a carteira começa em zero.

Anúncios premiados e compras com dinheiro real permanecem planejados: nenhum anúncio, pagamento ou crédito fictício por essas fontes está implementado.

## Abertura e coleção

Uma abertura custa **100 IP** e entrega uma carta. São 15 cartas, três por raridade; os emblemas vetoriais representam farm, trocas, builds, macro e visão.

| Raridade | Chance padrão | Níveis extras na habilidade | IP por repetida |
| --- | ---: | ---: | ---: |
| Normal | 60% | +1 | 10 |
| Rara | 25% | +2 | 20 |
| Épica | 10% | +3 | 35 |
| Lendária | 4% | +4 | 50 |
| Mítica | 1% | +5 | 75 |

Dentro de cada raridade, as três cartas têm chances iguais. Após nove aberturas consecutivas sem épica ou superior, a décima entrega épica ou superior: 10/15 épica, 4/15 lendária e 1/15 mítica. Obter qualquer uma dessas raridades reinicia a contagem, inclusive quando a carta é repetida.

Cartas novas entram na coleção e precisam ser equipadas. Até três cartas diferentes podem ficar equipadas; seus bônus se somam, inclusive quando afetam a mesma habilidade. As habilidades compradas mantêm limite 20; as cartas acrescentam níveis efetivos para a simulação, sem alterar custos ou níveis comprados. Trocar cartas durante uma partida só afeta a próxima. Cópias adicionais devolvem IP automaticamente e não multiplicam o bônus.

A compra é registrada antes da revelação visual. Em caso de falha de gravação, saldo, coleção e garantia são restaurados. Equipamentos e recompensas de partida também usam a gravação com reversão existente.

## Compatibilidade

O formato de save passa a v5, adicionando carteira IP, coleção, cartas equipadas, contador de garantia e recordes de elo. Saves v1–v4 continuam aceitos, com coleção vazia e sem pagamento retroativo de conquistas: o elo atual vira o recorde inicial. As migrações antigas de estudos permanecem intactas.

Os valores de custo, chances e cartas ficam em `game/scripts/card_catalog.gd`. As recompensas de progressão ficam em `game/scripts/progression.gd`.
