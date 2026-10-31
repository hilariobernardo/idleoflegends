# Atualização vigente — v0.8

Mapa aprovado integrado. Navegação sobre passagens da imagem e gank aleatório após seis campos; detalhes em docs/MAPA-v08.md. Preferência do usuário: respostas mínimas, poucos comentários e nenhum teste novo sem pedido explícito.

---

# Histórico — v0.7

Modo de teste com XP ilimitado, sessão zerada ao abrir e sem persistência. Botão de reinício, notação K/M/B/T, campos sem marcadores e jungler sem J. Proposta de mapa gerada mas não integrada: aguardar avaliação do usuário, depois calibrar rotas e campos na imagem aprovada. Detalhes em docs/TESTE-v07.md.

---

# Histórico — v0.6

Movimento padrão 3× o antigo, apresentado como 1×; relógio sem aceleração, limite de 90 segundos preservado. Junglers limpam três campos inferiores e três superiores antes de gankar. Nova arte aguarda imagem do usuário. Sem compra de velocidade extra nem novo APK nesta etapa. Detalhes: docs/MOVIMENTO-v06.md.

---

# Histórico — v0.5

Rolagem por gesto corrigida, tela adaptável por expansão, escolha de modo obrigatória ao abrir. Combate com variação de execução simétrica por time (0,80–1,20). Seis jornadas até Ranked e comparação antes/depois registradas em docs/VALIDACAO-v05.md. Custos e ganhos v0.4 mantidos com base nesses cenários. Sem novo APK; teste atual no computador.

---

# Histórico — v0.4

Pedido do usuário: ganhos mais exponenciais, compras muito mais caras conforme evolui e elos diferentes entre Normal e Ranked. Manter duas horas offline. Desejo futuro de retorno frequente e anúncios; nenhum anúncio foi implementado nesta etapa.

Implementado para teste: ganho marginal de Estudos ×1,6 por nível, custo ×2,4 por compra, habilidades ×2 por nível e XP de vitória ×1,16 por divisão. Taxas e custos iniciais continuam; limite de 20 níveis. Detalhes atuais e fórmulas estão no README.md.

Normal: Sal, Barro, Pedra, Cobre, Aço, Titânio, Lenda (IV–I). Ranked: Ferro, Bronze, Prata, Ouro, Platina, Esmeralda, Diamante (IV–I), Mestre, Grão-Mestre, Challenger (sem divisões). Nomes do LoL usados provisoriamente no protótipo; não há decisão de publicação. Os limiares locais de elite são escolhas de balanceamento, não reprodução do sistema competitivo de servidores do LoL.

Saves migram para v4 preservando progresso e liquidando tempo antigo na taxa antiga. A nova economia ainda precisa de teste de ritmo com o jogador.

---

# Histórico até v0.3 — regras abaixo substituídas quando conflitarem com a atualização acima
# Planejamento do jogo idle de MOBA

Atualizado em 29 de outubro de 2026 — protótipo v0.3.

## Origem e limites do contexto

O registro inicial reuniu trechos recuperados dos chats **“Criar jogo idle mobile”** e **“Branch · Criar jogo idle mobile”** do projeto **“jogo idle para celular”**. O histórico completo não estava disponível. As decisões recentes abaixo vêm diretamente da conversa atual; nomes, valores e regras complementares escolhidos para implementar o protótipo permanecem provisórios.

## Definições expressas pelo usuário

- Tela inicial com **Normal Game, Ranked, ARAM e URF**; somente Normal Game desbloqueado no início.
- **XP para desbloquear novos modos**.
- Ganhar XP mesmo com o jogo fechado, representando aprendizado fora das partidas: vídeos, tutoriais, coaches e estudo de competições.
- Permitir melhorar os estudos repetidamente, aumentando sua geração de **XP por segundo**.
- Usar a mesma produção de estudos com o jogo aberto e fechado, com acúmulo offline limitado a **2 horas**.
- Escalada também no Normal Game: começar em **Sal IV**, ganhar **25 pontos por vitória**, perder **25 por derrota** e subir para Sal III ao chegar a **100 pontos**.
- Aumentar o XP recebido nas vitórias conforme a progressão avança.
- Aumentar a dificuldade das partidas conforme a escalada: um jogador fraco perde mais; melhorias devem ajudar a continuar vencendo.
- Exigir um patamar de progressão e **muito XP** para comprar o acesso à Ranked.
- Ideia anterior para URF: **dobro de XP**, acesso por vídeo ou pagamento para desbloqueio permanente. A duração do acesso por vídeo ainda não está definida.

## Conceito preservado do resumo anterior

Jogo 2D para celular em Godot, paródia de MOBA com partidas automáticas, duas equipes de cinco personagens e mapa de três rotas. As habilidades permanentes são **Farm, Trocas, Builds, Macro e Visão de Mapa**. Ouro e equipamentos pertencem à partida; XP é o recurso permanente. ARAM terá uma rota. Esses pontos estavam preservados no resumo anterior, sem todas as mensagens originais de aprovação disponíveis.

## Escopo implementado na v0.3

O ciclo é **jogar → ganhar XP e disputar pontos → melhorar habilidades ou investir no aprendizado → enfrentar divisões mais fortes**. O treino também acumula XP durante a ausência e credita ao retornar.

| Sistema | Comportamento |
| --- | --- |
| Partida | 5 contra 5, três rotas, automática, até 90 segundos de simulação |
| Normal e Ranked | Jogáveis, com escaladas independentes e requisitos para desbloquear Ranked |
| Aprendizado | Estudos com níveis permanentes comprados com XP; produção cumulativa por segundo, igual online e offline, com limite de 2 horas de ausência |
| Dificuldade | Habilidades adversárias crescem com a divisão e usam as mesmas fórmulas do jogador |
| Persistência | Save v3 com migração de v1 e v2, incluindo níveis de estudos, relógio, escaladas e modo |
| ARAM e URF | Apresentados como planejados |
| Plataforma | Computador, com interface pensada para celular |

O aprendizado é uma atividade fictícia do personagem dentro do jogo. Não depende de serviços externos, anúncios, vídeos reais ou pagamentos. Somente o treino rende durante o fechamento: não há simulação de partidas offline. Não há APK nem publicação em lojas.

## Escolhas provisórias para teste

Estas escolhas completam as regras solicitadas pelo usuário; ainda precisam ser avaliadas jogando:

- **Elos:** Sal → Bronze → Prata → Ouro → Platina → Diamante → Mestre, todos IV–I. Teto em Mestre I, 99 pontos. Derrota abaixo de zero rebaixa; piso em Sal IV, 0 pontos.
- **Ranked:** desbloqueio permanente por **10.000 XP**, exigindo estar em **Bronze IV ou acima no Normal** no momento da compra. A Ranked começa sua própria escalada em Sal IV.
- **Recompensas Normal:** vitória **120 + 30 × índice da divisão** XP; derrota **70 XP**. Índice 0 é Sal IV, 1 é Sal III, 4 é Bronze IV.
- **Ranked:** recompensas multiplicadas por **1,5** e adversários com **+2 níveis** de habilidade.
- **Adversários:** nível de habilidade **0,65 × índice da divisão**, aplicado às cinco habilidades. A força do adversário não aumenta automaticamente quando o jogador compra melhorias.
- **Vídeos de dicas:** começam no nível 1 grátis; cada nível produz **1 XP/s**. A primeira melhoria, para nível 2, custa **100 XP**.
- **Tutoriais:** começam no nível 0; primeira compra de **300 XP**, produção de **2 XP/s por nível**.
- **Competições:** começam no nível 0; primeira compra de **1.200 XP**, produção de **4 XP/s por nível**.
- **Coach:** começa no nível 0; primeira compra de **4.000 XP**, produção de **10 XP/s por nível**.
- **Níveis dos estudos:** limite provisório de **20** por atividade. Cada compra aumenta permanentemente um nível; preço cresce por fator **1,5** a cada compra, arredondado ao inteiro mais próximo. Produção total é a soma do nível de cada atividade multiplicado por sua taxa.
- **Exibição online:** o total de XP atualiza a cada segundo. Novos níveis só aumentam ganhos posteriores à compra.
- **Habilidades:** custo inicial **60 XP**, fator **1,42** por nível, limite **20 níveis**.
- **Partida:** até **90 segundos de simulação**.

As sugestões antigas de **2.000 XP para Ranked** foram substituídas pelo valor de teste acima. **5.000 XP para ARAM**, um contador separado de nível da conta e **uma partida URF por anúncio** continuam sugestões não aprovadas nem implementadas.

A versão anterior usava atividades de compra única, taxas por hora e limite de 8 horas. O pedido mais recente substitui esse modelo por estudos melhoráveis, taxas por segundo iguais online e offline e **2 horas de acúmulo offline**. Estas três regras são decisões do usuário; os valores de produção, preços, crescimento dos custos e limite de 20 níveis continuam escolhas provisórias.

## Persistência e limitações

Saves v2 migram para v3 preservando XP, melhorias, estatísticas, escaladas e modo. Estudos já comprados viram nível 1; os demais ficam no nível 0. Antes de aplicar as novas taxas, o rendimento pendente é creditado pelas taxas antigas por hora, com limite de **2 horas**. As novas taxas por segundo valem a partir da migração, evitando recompensar retroativamente horas antigas com os novos valores.

Saves v1 mantêm XP, melhorias e estatísticas na migração para v3. Nesse caso, a contagem do aprendizado começa no momento da migração, sem recompensa por períodos anteriores. Saves inválidos ou de versão futura são preservados; operações que falham ao gravar devem reverter suas alterações.

O treino usa o relógio local, sem servidor. Não há recompensa adicional por carregar repetidamente o mesmo intervalo. Se o relógio retroceder, o treino espera alcançar o horário salvo. Adiantar manualmente o relógio pode influenciar os ganhos; proteção por horário de servidor fica para uma etapa posterior.

## Pontos pendentes

1. Testar o tempo para subir de divisão e comprar Ranked, equilibrando partidas e renda offline.
2. Ajustar dificuldade e impacto de cada habilidade, evitando saltos excessivos de chance de vitória.
3. Detalhar ganks, visão, equipamentos e objetivos da simulação.
4. Definir e implementar ARAM e URF.
5. Definir a duração do acesso por anúncio e implementar monetização em etapa própria.
6. Escolher a plataforma móvel inicial e preparar testes no aparelho.

O planejamento deve evoluir com as decisões do usuário. Valores e regras complementares de teste continuam provisórios até serem definidos.





