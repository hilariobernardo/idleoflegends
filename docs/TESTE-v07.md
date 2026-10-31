# v0.7 — modo de teste e proposta de mapa

Ao abrir o jogo normalmente, inicia uma sessão nova, em Sal IV, apenas Normal disponível e XP ilimitado (∞ XP). As compras de habilidades/estudos não descontam saldo. Ranked mantém o requisito de Barro IV; o custo não limita a compra no modo de teste. Ouro dentro da partida continua sendo parte da simulação, para não alterar automaticamente a força do time. Não há leitura/gravação de save nem crédito offline nesta sessão. O arquivo de progresso antigo não foi apagado nem sobrescrito. O botão Recomeçar teste zera a sessão e interrompe a partida atual. A infraestrutura antiga de persistência permanece apenas para testes isolados e futura retomada.

Valores grandes usam K (mil), M (milhão), B (bilhão) e T (trilhão), com uma casa decimal e vírgula: 1,5K; 2,3M. Custos exatos continuam no tooltip e as comparações de compra usam inteiros. Valores abreviados são truncados, não arredondados para cima. Referência pesquisada: https://idlerunner.app/wiki/en/big-numbers .

Removidos do mapa atual: números, círculos e indicadores de limpeza dos campos, letra J e destaque especial do jungler. As posições e a lógica dos campos continuam internas.

## Proposta visual, ainda NÃO integrada

Arquivo: concepts/mapa-proposta-01.png. Criado com a ferramenta integrada image_gen a partir da referência enviada pelo usuário. Aprovação da aparência pendente. O fundo, rotas e coordenadas atuais do jogo não foram substituídos. Após aprovação, mapear as seis clareiras por lado em coordenadas normalizadas da imagem final e ligar os percursos à geometria real, para que os personagens não atravessem pedras/árvores. Não reutilizar cegamente os pontos do mapa vetorial antigo. A proposta é conceitual, não um mapa já calibrado para a simulação nem garantia jurídica.

Direção do prompt: mapa de arena minimalista visto de cima, pedra clara, jardim e floresta de jade, água turquesa; bases opostas, três rotas e seis clareiras por time; identidade artística própria; sem texto, números, personagens ou marcadores. A referência orienta apenas relações espaciais.

Validação: test_practice (não ler/escrever disco, compras sem débito, reinício e notação), test_flow, test_progression, test_idle_ladder, test_mobile_ui e test_jungle passaram. Capturas verificadas em artifacts/practice-v07.png e jungle-v07.png. Nenhum APK gerado.
