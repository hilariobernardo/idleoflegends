# v0.8 — mapa aprovado e navegação

O mapa aprovado está integrado em game/assets/arena.png, sem alterar a arte. Rotas, campos, bases, torres e unidades usam o mesmo retângulo normalizado. A área do mapa acompanha a largura da interface.

A navegação usa um grafo de passagens extraído da imagem, com ajustes para pisos das bases, clareiras e rochas cujos reflexos poderiam parecer chão. Os personagens seguem os segmentos desse grafo, sem ir diretamente de um campo a outro. Rotas de ida, gank e retorno usam o mesmo sistema; ao morrer, o jungler reinicia a limpeza. Campos e caminhos são internos e não exibem números ou letras.

Ao concluir os seis campos, cada jungler sorteia uniformemente topo, meio ou baixo usando o gerador da simulação. Pode repetir a escolha; não há mais ciclo fixo topo/meio/baixo. O gank entra perto do centro da rota e depois passa ao combate normal.

Arquivos: scripts/map_layout.gd, assets/arena_navigation.json. A geração reprodutível está em .tools/build_navigation.py; diagnóstico visual em artifacts/navigation-v08.png. A classificação de pixels é uma aproximação da arte ilustrada, com correções manuais; futuros ajustes de arte exigem recalibrar a navegação. Não é colisão 3D derivada dos objetos da ilustração.

Antes do pedido para não fazer testes automaticamente, passaram os testes de fluxo, jungle, navegação, simulação, rolagem, modo de teste e progressão. Verificados trajetos contínuos, todos os destinos acessíveis e escolha das três rotas em diferentes sementes. Nenhum teste novo será iniciado sem pedido do usuário. Modo de teste com XP ilimitado preservado; nenhum APK gerado.
