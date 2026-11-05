# Nexo Idle — protótipo v0.11

Abra `Jogar.cmd` para jogar ou importe `game/project.godot` no Godot para editar. O APK v0.11 reúne cartas com efeitos percentuais, objetivos e painel inferior e foi exportado para Android; a instalação em aparelho físico ainda não foi validada.

No Windows, extraia a pasta completa e abra **Jogar.cmd**. O atalho procura um Godot 4.5 ou superior já instalado no PATH, na pasta do projeto ou em `.tools/godot`, prepara os recursos e inicia o jogo. Ele não baixa nem instala o Godot. Cópias preparadas pelo atalho anterior continuam sendo reutilizadas. Você também pode indicar um executável com `Jogar.cmd -GodotPath "C:\caminho\Godot.exe"`. Os logs ficam em `.tools/`, fora do Git. Veja abaixo como instalar o Godot uma única vez no Windows.

[**Baixar APK v0.11 pelo GitHub**](https://github.com/hilariobernardo/idleoflegends/raw/refs/heads/work/builds/Nexo-Idle-0.11.apk)

O código-fonte já inclui a animação de compra e a evolução das cartas descritas abaixo. O APK v0.11 acima é anterior a essas mudanças; nenhum novo APK foi gerado nesta etapa.

## Cartas e evolução

A aba **Cartas** traz 15 cartas de raridades Normal, Rara, Épica, Lendária e Mítica. Cada abertura custa **100 Idle Points (IP)** e revela a carta com animação, brilho da raridade e opção de pular. Equipe até três cartas para ganhar bônus na próxima partida. IP vem de novas divisões, novos elos e marcos de dez vitórias. Há garantia de épica ou superior em até dez aberturas enquanto houver cartas dessas raridades abaixo do máximo. Anúncios e pagamentos continuam planejados.

Cada carta começa no **nível 1** e cada repetida aumenta **1 nível, até o 5**, sem devolução de IP. Cinco estrelinhas abaixo da carta indicam o nível na coleção e na revelação: uma dourada por nível e as demais apagadas. Cada nível acrescenta 25% do bônus inicial, até dobrá-lo no nível máximo, com arredondamento para porcentagens inteiras. Cartas no máximo saem do sorteio: você recebe outra carta que ainda possa evoluir. Quando todas estiverem no máximo, a compra é bloqueada sem cobrar IP. A coleção mostra o nível, o bônus atual e o próximo.

**Exemplos no nível 1:** Tesouro do dragão dá +30% de dano contra Dragon/Baron; Colheita dourada dá +12% de XP ao terminar partidas; Lâmina da tempestade dá 20% de chance de crítico. No nível 5, esses valores são +60%, +24% e 40%. Nenhuma carta concede níveis de habilidade.

**Evolução** reúne habilidades e estudos em dois grupos com blocos de duas colunas. O modo de teste começa com **300 IP**, mantém XP ilimitado e não salva a sessão. Consulte [as regras de níveis, sorteio e animação](docs/CARTAS-NIVEIS.md) e [os efeitos de cada carta](docs/CARTAS-v011.md).

## Alterações recentes

- Inicialização: corrigido o erro de `arena.png/.ctex` em cópias sem cache `.godot`. O mapa lê o PNG original no código-fonte e usa a textura importada nas exportações. Adicionado teste de abertura/mapa/partida; atualizados testes antigos de abas, velocidade, save e selva. Dez scripts de teste aprovados com Godot 4.6.3, além da abertura de um pacote PCK; nenhum novo APK.
- Windows/Ponytail: removido o download/instalador automático do Godot; o atalho reutiliza instalações existentes e mantém a importação dos recursos. Instalação única no Windows documentada via WinGet. Adicionada a skill Ponytail oficial ao projeto, com licença MIT; sem mudanças na lógica do jogo nem novo APK.
- Corrigido `Jogar.cmd`: detecta Godot portatil/fora do PATH ou baixa uma copia oficial verificada por SHA256, sem administrador. Importa recursos antes de abrir para evitar erro de textura do mapa em clones novos. Versoes Windows x64, x86 e ARM64 contempladas; nao altera o progresso do jogo.
- Recuperadas as mudanças de animação e níveis; adicionadas cinco estrelinhas abaixo das cartas na coleção e na revelação. Testes de cartas e interface cobrem evolução, exclusão de cartas no máximo, virada completa, pular, bloqueio de compras e reinício durante a animação.
- Configuração do projeto: a skill `game-dev` passou a ser obrigatória para toda criação, implementação, correção, refatoração ou modificação do jogo.
- Cartas evoluem do nível 1 ao 5 com repetidas, fortalecendo seus bônus; cartas no máximo são substituídas no sorteio e a coleção completa bloqueia compras sem gastar IP. Cópias antigas viram níveis, preservando equipamentos e saldo.
- Compra de cartas ganhou animação de invocação e virada, brilho por raridade, destaque de subida de nível e opção de pular; toques repetidos não compram durante a revelação. Coleção mostra níveis e bônus atuais/próximos. Alterações apenas no código-fonte, sem novo APK.
- v0.11: cartas agora concedem efeitos percentuais próprios, sem aumentar níveis de habilidades: XP por partida, ouro, dano contra jogadores/objetivos/estruturas, críticos, velocidade, vida, resistência e renascimento.
- Bônus de combate e XP usam as cartas equipadas no início da partida. Trocas valem para a próxima; a coleção existente foi preservada.
- v0.10: adicionadas 15 cartas com cinco raridades, Idle Points, até três cartas equipadas, devolução por repetidas e garantia de épica ou superior.
- Habilidades e estudos agora formam dois grupos em grade de duas colunas, disponíveis na aba Evolução e no painel inferior durante a partida.
- Integradas as melhorias do branch work (Dragon/Baron e velocidade 2×). APK atualizado entregue por download direto do GitHub, com a mesma orientação registrada no AGENTS.md.
- O histórico de alterações também passou a ser mantido no AGENTS.md para orientar os próximos agentes.
- Registrada a orientação para documentar as próximas alterações neste histórico.
- Dragon e Baron foram reposicionados nos covis inferior e superior do rio. Os jogadores receberam posições individuais ao redor dos objetivos, com barras de vida ajustadas ao tamanho do mapa.
- O modo de teste passou a iniciar em 2×, com botão para alternar entre 1× e 2× durante as partidas.

## Dragon e Baron

Baron fica no covil superior do rio e Dragon no covil inferior, afastados do mid. Cada personagem tem uma posição própria ao redor do objetivo, com espaço para sua barra de vida; mortes não reorganizam as posições dos sobreviventes. Os trajetos incluem as entradas do rio e dos covis.

O modo de teste começa em **2×**. O botão **1× / 2×** alterna a velocidade da partida inteira: movimento, ataques, renascimento, objetivos e relógio. A seleção permanece nas próximas partidas; RECOMEÇAR TESTE volta a 2×.

Dragon aparece aos 20 e 45 segundos, disputado por jungler, atirador e suporte. Se ainda estiver vivo no segundo horário, não nasce uma cópia. Baron aparece aos 65 segundos e reúne os cinco personagens vivos de cada equipe, com prioridade sobre Dragon. Os personagens percorrem os caminhos do mapa e atacam adversários próximos antes do monstro; depois retornam às rotas ou à selva.

Dragon tem 300 de vida e concede +8% de dano por conquista, até +16% durante a partida. Baron tem 600 de vida e concede +30% de dano contra torres e nexo por 20 segundos. Os monstros não revidam. O dano é aplicado simultaneamente; conquista o time que causar mais dano no último passo da simulação, com sorteio em empate. Bônus valem para todo o time, sobrevivem ao renascimento e são zerados na próxima partida. Não há pontos extras diretos na decisão do vencedor.

Os objetivos aparecem com identificação e vida no mapa, e o painel informa nascimentos, conquistas e bônus ativos. Valores iniciais de balanceamento.

## Mapa integrado — v0.8

Mapa aprovado integrado, com percursos ligados às passagens da imagem e sorteio de uma das três rotas após cada limpeza de seis campos. Consulte docs/MAPA-v08.md. O modo de teste continua ativo.

## Modo de teste — v0.7

O jogo agora começa do zero a cada abertura, com XP ilimitado e sem carregar/gravar progresso. Use RECOMEÇAR TESTE para zerar a sessão. Valores grandes usam K/M/B/T. Removidos os marcadores dos campos e o J do jungler. Proposta de mapa em docs/concepts/mapa-proposta-01.png, aguardando avaliação antes de integrar. Detalhes: docs/TESTE-v07.md. As regras de salvamento e offline descritas no histórico abaixo não se aplicam à sessão de teste atual.

## Movimento e jungle — v0.6

Movimento 3× mais rápido como padrão 1×, sem acelerar o relógio. Os junglers fazem seis campos antes do gank, com percurso e campos visíveis. Detalhes e testes em docs/MOVIMENTO-v06.md. A velocidade extra comprável e a nova arte do mapa ficam para depois.

## Correções da v0.5

Arraste a tela com o mouse para testar a rolagem por toque. A interface expande para a proporção da janela, e toda abertura exige escolher um modo antes da partida. O combate recebeu variação simétrica por time para suavizar diferenças pequenas de nível. Resultados antes/depois e jornadas até Ranked estão em `docs/VALIDACAO-v05.md`. O APK existente é da v0.4 e não foi atualizado nesta etapa.

## Economia exponencial em teste

Estudos geram XP/s. Cada atividade tem até 20 níveis. A produção total de uma atividade é `arredondar(base × (1,6^nível − 1) / 0,6)`. Assim, cada novo nível acrescenta mais produção que o anterior. A tela mostra a produção atual e a próxima.

| Estudo | Produção no nível 1 | Primeira compra |
| --- | ---: | ---: |
| Vídeos | 1 XP/s, nível 1 gratuito | 100 XP para nível 2 |
| Tutoriais | 2 XP/s | 300 XP |
| Competições | 4 XP/s | 1.200 XP |
| Coach | 10 XP/s | 4.000 XP |

O preço multiplica por **2,4 a cada compra**, crescendo mais rápido que a produção. As habilidades de combate custam `60 × 2^nível`: ganhar XP não significa adquirir todos os níveis imediatamente. Valores provisórios para testes de ritmo, sem garantia de retenção.

A produção é igual online e offline, com atualização a cada segundo e limite de **duas horas por ausência**. Ficar um dia fora paga no máximo duas horas. Estudos representam atividades fictícias do personagem. Anúncios e pagamentos ainda não estão implementados.

## Elos separados

- **Normal:** Sal → Barro → Pedra → Cobre → Aço → Titânio → Lenda. Todos têm IV, III, II, I; teto Lenda I, 99 pontos.
- **Ranked:** Ferro → Bronze → Prata → Ouro → Platina → Esmeralda → Diamante → Mestre → Grão-Mestre → Challenger. Ferro a Diamante têm IV–I; os três últimos não têm subdivisões.

Ambos mantêm +25 por vitória e −25 por derrota, piso zero e promoção a cada 100 pontos nas divisões. Na Ranked deste protótipo local, Mestre começa em 2.800 pontos totais, Grão-Mestre em 3.000 e Challenger em 3.300, com teto 3.999. Esses limiares são provisórios: o protótipo reproduz a sequência de elos, não a classificação por vagas/MMR/servidor do LoL.

Referência da sequência: [Riot — tiers e divisões](https://support.riotgames.com/en-us/league-of-legends/gameplay/ranked-tiers-divisions-and-queues).

Ranked exige **Barro IV no Normal + 10.000 XP** para desbloqueio permanente. Vitória no Normal rende `arredondar(120 × 1,16^índice_da_divisão)`; derrota rende 70. Ranked multiplica recompensas por 1,5. Rivais recebem 0,65 nível por divisão, mais 2 na Ranked, limitados a 19,5 para permitir enfrentá-los com habilidades de nível 20. ARAM e URF continuam planejados.

## Progresso e testes

`user://progress.json` usa formato v6, com carteira IP, níveis das cartas, equipamentos e garantia. Saves v1–v5 continuam aceitos; as quantidades de cartas do v5 viram níveis, limitados a 5, sem perder cartas descobertas, equipamentos ou IP. XP, habilidades, níveis dos estudos, pontos e desbloqueios existentes são preservados; os nomes dos elos mudam conforme o modo. Na migração v3, o tempo pendente é pago na taxa linear anterior antes de ativar a curva exponencial. v2 usa a taxa antiga por hora; v1 inicia o treino sem renda retroativa. Relógio local, limite offline e proteção contra recompensa duplicada continuam ativos.

Testes em `game/tests/`: progressão, economia/elos/migração, fluxo da interface e simulação. Referências sincronizadas em `sources/` são somente leitura.

## APK para teste Android

O arquivo `builds/Nexo-Idle-0.11.apk` é uma versão de depuração para testes, compatível com Android 7.0 (API 24) ou superior em dispositivos ARM. Transfira-o ao celular, abra-o e autorize a instalação de aplicativos dessa origem se o Android solicitar. Não é uma versão para publicação na Play Store. Esta compilação usa uma nova assinatura de depuração; se houver um APK antigo instalado com outra assinatura, o Android não permitirá atualizar por cima. Desinstalar o antigo remove seus dados locais. O modo de teste atual não salva o progresso. Não foi possível testar a instalação ou a interface em aparelho físico, pois nenhum dispositivo estava conectado. Os resultados e o roteiro de teste estão em `docs/TESTE-ANDROID.md`.





## Usar este repositorio em outro computador

No Windows, se o Godot já estiver instalado, reutilize essa instalação. Se precisar instalar, execute uma vez no PowerShell:

```powershell
winget install --exact --id GodotEngine.GodotEngine --version 4.6.3
```

Feche e reabra o terminal após a instalação para atualizar o PATH; confirme com `godot --version`. O pacote WinGet cria o comando `godot` e instala o editor fora do repositório, permitindo reutilizá-lo em outros projetos. O comando acima foi conferido no manifesto oficial do WinGet para a versão 4.6.3, mas não foi executado no seu computador por esta sessão na nuvem.

Se o WinGet não estiver disponível, baixe o editor padrão para a arquitetura do seu Windows na [release oficial Godot 4.6.3](https://github.com/godotengine/godot/releases/tag/4.6.3-stable), extraia em uma pasta permanente e indique o executável com `Jogar.cmd -GodotPath "C:\caminho\Godot.exe"`.

Clone ou baixe este repositório, extraia a pasta completa e abra `Jogar.cmd`. Se o editor não for encontrado, o atalho informa como instalá-lo, sem fazer downloads. Para editar, importe `game/project.godot` no Godot 4.5 ou superior e pressione F5. No Linux e macOS, instale o Godot e use `godot --path game`. A validação anterior do jogo foi feita com Godot 4.6.3.

O ambiente Codex pode editar os arquivos clonados. A interface grafica do jogo exige um computador com Godot e suporte grafico; conectar o repositorio nao instala automaticamente o editor. Ferramentas locais Android, APK antigo e capturas nao foram incluidos no repositorio. As referencias historicas a esses arquivos descrevem o computador original.

O atalho foi revisado estaticamente; sua execução no Windows ainda precisa ser conferida no computador do jogador, pois esta sessão executa Linux. A correção posterior do mapa foi testada no Godot 4.6.3, a pedido do usuário: os dez scripts `game/tests/test_*.gd` passaram em uma cópia sem cache `.godot`. Também passou o teste de inicialização usando um pacote PCK exportado, que contém apenas a textura importada, sem o PNG original. Isso não substitui a validação em um aparelho Android ou no Windows; nenhum novo APK foi gerado.

Para verificar a abertura, a imagem do mapa e o início de uma partida sem precisar importar recursos antes:

```sh
godot --headless --path game --script res://tests/test_startup.gd
```

## Ponytail para desenvolvimento

A [skill Ponytail](.agents/skills/ponytail/SKILL.md) está instalada no projeto e referenciada no `AGENTS.md`. Ela orienta o assistente a entender o fluxo existente, reutilizar recursos e evitar código e dependências desnecessários. A simplificação aplicada ao atalho removeu o instalador embutido; não há promessa de ganho de FPS nem alteração da lógica do jogo.

Origem: [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail/tree/96608e078b2d5ea607c5c3b8b5a54d1c1fba6846), revisão `96608e0`, com [licença MIT](.agents/skills/ponytail/LICENSE). Esta integração usa a skill local; comandos e hooks do plugin completo não foram instalados. As regras existentes do projeto, incluindo a política de testes, continuam valendo.
