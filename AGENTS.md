# Project instructions

Godot 4 project in game/project.godot; validated with 4.6.3, also used by the portable Windows launcher. Assets and navigation are in game/assets. Default play mode is a fresh session with unlimited XP and no save writes.

Keep replies short. Do not run tests unless the user explicitly requests them.
For any request to create, implement, fix, refactor or modify game functionality, use the installed `game-dev` skill and follow its workflow before changing the project.
For every project change, add a concise summary of what was added or fixed to the history below and to the README's "Alterações recentes" section, in the same commit. Keep earlier entries so future agents can follow the project's history.
Do not commit local SDKs, engines, caches, signing keys, credentials or generated builds.
When the user requests an APK download, deliver a verified GitHub URL, never only a local workspace link. Prefer GitHub Releases. For this project's established direct-download workflow, the explicitly requested versioned APK and its checksum in builds/ are the exception to the generated-build restriction. Do not include any other build tooling or signing material.
Before publishing, fetch and integrate the latest target branch without discarding existing features. Keep the README download link and APK version consistent with the delivered build.
Navigation generation: scripts/build_navigation.py (Python, Pillow, NumPy), run from repository root. After map changes, paths must align with the approved image.

## Histórico de alterações

- Windows: `Jogar.cmd` passou a detectar Godot no PATH ou portatil e, na ausencia, baixar Godot 4.6.3 oficial (x64/x86/ARM64) com SHA256 fixado. Prepara os recursos antes de abrir, sem administrador nem alterar PATH. Motor/logs ficam em `.tools/`, ignorado pelo Git. Nao foi executado em Windows nesta sessao Linux.
- Cartas: recuperada animação de abertura com virada/brilho por raridade e opção de pular; repetidas evoluem do nível 1 ao 5, com cinco estrelinhas abaixo da carta na coleção e na revelação. Cada nível acrescenta 25% do bônus base. Cartas no máximo saem do sorteio; coleção completa bloqueia compra sem gasto. Save v6 converte cópias antigas em níveis. Cobertura nos testes de cartas e interface; APK v0.11 permanece anterior às mudanças.
- Configuração: a skill `game-dev` passou a ser obrigatória para toda criação, implementação, correção, refatoração ou modificação do jogo.
- v0.11: cartas passaram a ter efeitos percentuais próprios (XP por partida, ouro, dano específico, crítico, velocidade, resistência, vida e renascimento), sem conceder níveis de habilidades. Efeitos e recompensa de XP são fixados no início da partida; coleção existente preservada.
- v0.10: cartas gacha com cinco raridades, Idle Points, três equipamentos, devolução por repetidas e garantia de épica; habilidades e estudos em duas colunas, também no painel inferior da partida.
- v0.10: integradas as mudanças do branch work (Dragon/Baron, posições dos jogadores e velocidade 2×); entrega do APK por link direto do GitHub, com histórico e README sincronizados.
- O histórico de alterações também passou a ser mantido neste arquivo para orientar os próximos agentes.
- Dragon e Baron foram reposicionados nos covis inferior e superior do rio. Cada jogador recebeu uma posição própria ao redor dos objetivos, e as barras de vida foram ajustadas ao tamanho do mapa.
- O modo de teste passou a iniciar em 2×, com botão para alternar entre 1× e 2× durante as partidas.
- Foi criada no README uma seção de alterações recentes para registrar adições e correções.
