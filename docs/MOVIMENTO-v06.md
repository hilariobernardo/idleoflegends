# v0.6 — movimento e jungle

A pedido do jogador, a velocidade de deslocamento das unidades é agora 3× a anterior e representa o padrão 1×. O relógio, farm por segundo, ataques, renascimento e renda de estudos não são multiplicados. O botão não alterna mais a aceleração global. Compra de velocidade extra não está implementada. O limite permanece 90 segundos; como antes, destruir um nexo pode encerrar uma partida antecipadamente. Deslocamento mais rápido pode mudar resultados e duração até essa destruição.

Os dois junglers percorrem seis campos em sua metade do mapa, três inferiores e três superiores, com 1,5 segundo de limpeza por campo. Só depois entram numa rota, perto de um aliado vivo quando disponível, para gankar durante até oito segundos. Alternam topo, meio e baixo entre ciclos e depois repetem o circuito. Não atacam unidades ou torres remotamente enquanto estão na jungle. Ao morrer, voltam à base e recomeçam o circuito. Os campos são uma representação simplificada, sem monstros individuais, invasões ou temporizadores próprios de reaparecimento. Cada limpeza rende 18 de ouro, modificado por Farm; enquanto fora da rota não há farm passivo adicional.

O mapa mostra os seis campos numerados por lado, campos já limpos escurecidos, indicador de limpeza e um J no jungler. O fundo atual continua vetorial. A substituição artística aguarda uma imagem de referência do usuário e não foi incluída nesta etapa.

Verificação: testes de seis campos em ordem, deslocamento contínuo, gank só após o circuito, dois times, renascimento e relógio sem aceleração. Testes de fluxo, economia, migrações, rolagem, dimensões e simulação passaram. Inspeção visual por captures em artifacts/jungle-8s.png e jungle-24s.png.

Nas três jornadas automatizadas a 1×, com a estratégia de compras documentada na v0.5, a Ranked foi comprada em 27min11s, 28min18s e 30min34s. Cenários legados de aceleração 4× no log não representam uma opção disponível na v0.6. O script measure_journey.gd agora mede apenas o padrão disponível.

Nenhum APK novo gerado. Testes atuais no computador; progresso salvo preservado.
