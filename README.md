# Nexo Idle — protótipo v0.8

Abra `Jogar.cmd` para jogar ou `Abrir editor.cmd` para editar no Godot. O protótipo é testado no computador; a versão móvel ainda não foi exportada.

## Alterações recentes

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

`user://progress.json` usa formato v4. XP, habilidades, níveis dos estudos, pontos e desbloqueios existentes são preservados; os nomes dos elos mudam conforme o modo. Na migração v3, o tempo pendente é pago na taxa linear anterior antes de ativar a curva exponencial. v2 usa a taxa antiga por hora; v1 inicia o treino sem renda retroativa. Relógio local, limite offline e proteção contra recompensa duplicada continuam ativos.

Testes em `game/tests/`: progressão, economia/elos/migração, fluxo da interface e simulação. Referências sincronizadas em `sources/` são somente leitura.

## APK para teste Android

O arquivo `builds/Nexo-Idle-0.9.apk` é uma versão de depuração com Dragon, Baron e a tela de melhorias abaixo do mapa, compatível com Android 7.0 (API 24) ou superior em dispositivos ARM de 32 e 64 bits. Exportado com Godot 4.6.3, disponível neste ambiente, com assinatura verificada. Esta versão abre no modo de teste com XP ilimitado e sem salvar progresso. Transfira-o ao celular, abra-o e autorize a instalação de aplicativos dessa origem se o Android solicitar. Não é uma versão para publicação na Play Store. O progresso do celular é separado do progresso no computador. Não foi possível testar a instalação ou a interface em aparelho físico, pois nenhum dispositivo estava conectado. Os resultados e o roteiro de teste estão em `docs/TESTE-ANDROID.md`.





## Usar este repositorio em outro computador

Instale Godot 4.7.2, clone este repositorio e importe `game/project.godot`. Pressione F6/F5 no editor para executar a cena/projeto. Com o comando `godot` no PATH, use `godot --path game` ou `Jogar.cmd` no Windows. O mesmo projeto funciona no editor para Windows, Linux e macOS.

O ambiente Codex pode editar os arquivos clonados. A interface grafica do jogo exige um computador com Godot e suporte grafico; conectar o repositorio nao instala automaticamente o editor. Ferramentas locais Android, APK antigo e capturas nao foram incluidos no repositorio. As referencias historicas a esses arquivos descrevem o computador original.
