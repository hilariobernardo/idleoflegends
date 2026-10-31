# Validação v0.5 — interface e ritmo

30/10/2026. Nenhum APK novo foi gerado. O APK v0.4 existente não contém estas correções.

## Interface

A rolagem usa gestos nativos do ScrollContainer. Cartões, containers e botões deixam os eventos chegar até ele; a emulação de toque permite testar arrastando com o mouse no computador. O limiar é de 10 pixels de interface, e arrastar cancela o clique no botão. Trocar de página volta ao topo.

A tela agora expande a área disponível conforme a proporção da janela, em vez de preservar um retângulo fixo com faixas. Verificação no computador em 540×960, 540×1200, 540×1260 e 768×1024, com capturas em artifacts/mobile-*.png. A validação inclui toda a área da janela e a largura do conteúdo. Ainda é necessário confirmar os gestos e as áreas de sistema em um aparelho quando houver uma nova versão Android.

Toda abertura apresenta os quatro modos. No progresso novo, só Normal é liberado. A aba Partida e a chamada de iniciar partida não contornam a escolha. Progresso existente e desbloqueio da Ranked são preservados. Não foi adicionado sistema de login.

## Ajuste de combate

A execução de cada time varia entre 0,80 e 1,20 por partida, de modo simétrico e reproduzível por semente, multiplicando o poder ofensivo. As habilidades continuam afetando os mesmos atributos. Essa variação suaviza a transição de vitória/derrota garantida diante de diferenças pequenas de nível.

Contra rivais nível 4, em 20 sementes iguais antes/depois:

| Habilidades do time | Antes | Depois |
|---|---:|---:|
| Todas nível 0 | 0/20 | 0/20 |
| Todas nível 2 | 0/20 | 4/20 |
| Todas nível 4 | 10/20 | 11/20 |
| Todas nível 6 | 20/20 | 18/20 |
| Todas nível 8 | 20/20 | 20/20 |

Amostras pequenas não são probabilidades definitivas. Não foram alterados preços, ganhos exponenciais, requisito de 10.000 XP/Barro IV nem limite offline de duas horas.

## Começo e escalada: seis jornadas completas

O script measure_journey.gd usa as regras reais de compras, estudos, partidas, pontos e desbloqueio, com progresso em memória isolado. São três sementes em velocidade 1× e três em 4×, incluindo três segundos entre partidas. Ao final de cada partida, enquanto abaixo de Barro, investe até metade do saldo no estudo com melhor retorno menor que dez minutos e compra habilidades mais baratas até dois níveis acima do rival. Em Barro, economiza para Ranked. Não há ausências nesses cenários. É uma política de teste, não previsão do comportamento de todos os jogadores.

| Marco | Antes 1× | Depois 1× | Antes 4× | Depois 4× |
|---|---|---|---|---|
| Primeira habilidade | 1min33s | 1min33s | 26s | 26s |
| Primeira divisão | 7min40s–7min45s | 9min18s–10min51s | 2min10s–3min54s | 3min02s–3min54s |
| Primeiro Barro IV | 25min56s–28min59s | 26min20s–32min33s | 7min18s–8min58s | 9min04s–9min53s |
| Compra da Ranked | 27min43s–29min02s | 27min10s–32min33s | 19min–20min14s | 20min03s–21min52s |

No ritmo normal, a primeira compra chega no primeiro resultado e a Ranked aparece em cerca de meia hora nessa estratégia. Em 4× a escalada acontece antes da capacidade de pagar Ranked: os estudos continuam seguindo tempo real, intencionalmente. Esses resultados sustentam manter os custos atuais para o próximo teste no computador, em vez de alterá-los sem necessidade. O ajuste desta etapa é na previsibilidade excessiva do combate.

Logs: artifacts/journey-before.log, journey-after.log, balance-after.log. Scripts: game/tests/measure_journey.gd e measure_balance.gd. Testes de interface: game/tests/test_mobile_ui.gd; integração de modos e progresso: test_flow.gd. Os testes existentes verificam ganhos offline e preservação/migração do save.
