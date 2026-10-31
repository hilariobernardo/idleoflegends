# Project instructions

Godot 4.7.2 project in game/project.godot. Assets and navigation are in game/assets. Default play mode is a fresh session with unlimited XP and no save writes.

Keep replies short. Do not run tests unless the user explicitly requests them.
For every project change, add a concise summary of what was added or fixed to the history below and to the README's "Alterações recentes" section, in the same commit. Keep earlier entries so future agents can follow the project's history.
Do not commit local SDKs, engines, caches, signing keys, credentials or generated builds.
Navigation generation: scripts/build_navigation.py (Python, Pillow, NumPy), run from repository root. After map changes, paths must align with the approved image.

## Histórico de alterações

- O histórico de alterações também passou a ser mantido neste arquivo para orientar os próximos agentes.
- Dragon e Baron foram reposicionados nos covis inferior e superior do rio. Cada jogador recebeu uma posição própria ao redor dos objetivos, e as barras de vida foram ajustadas ao tamanho do mapa.
- O modo de teste passou a iniciar em 2×, com botão para alternar entre 1× e 2× durante as partidas.
- Foi criada no README uma seção de alterações recentes para registrar adições e correções.
