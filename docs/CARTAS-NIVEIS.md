# Níveis e abertura de cartas

## Compra e animação

Cada compra custa 100 IP e entrega uma carta. A interface mostra uma relíquia fechada, aproximação, vibração, virada e brilho na cor da raridade. O resultado distingue carta nova de subida de nível e mostra o bônus recebido. É possível pular a animação e depois continuar para a coleção.

A compra é registrada antes da animação. Pular ou fechar a apresentação não sorteia de novo nem cobra novamente. Novas compras e trocas de equipamento ficam bloqueadas durante a apresentação. Recomeçar a sessão cancela a animação. Uma falha de salvamento desfaz saldo, nível, garantia e estado do sorteador; o resultado não é apresentado como compra concluída.

## Evolução

- Primeira obtenção: nível 1. Cada repetida: +1 nível, até 5, sem devolver IP.
- Bônus por nível: `arredondar(bônus inicial × (1 + 0,25 × (nível − 1)))`.
- No nível máximo, os bônus são o dobro dos valores iniciais. Os limites de combinação dos efeitos continuam ativos.
- Exemplo: Colheita dourada concede 12%, 15%, 18%, 21% e 24% de XP nos níveis 1–5.
- O nível da carta não modifica os níveis das habilidades. Até três cartas diferentes podem ser equipadas.
- Subir uma carta equipada altera seus efeitos na próxima partida. Combate e XP da partida atual mantêm os valores copiados no início dela.

A coleção e a revelação mostram cinco estrelinhas abaixo da carta: uma estrela dourada por nível, com as restantes apagadas. A coleção também mostra o efeito atual, o efeito do próximo nível e a indicação de nível máximo. Cartas não descobertas têm as cinco estrelas apagadas e exibem o bônus do nível 1.

## Sorteio sem cartas no máximo

Cartas no nível 5 são retiradas das candidatas antes do sorteio. A abertura sempre entrega uma carta nova ou uma melhoria enquanto houver qualquer carta abaixo do máximo. Não há tentativas repetidas, cobrança adicional ou conversão em IP.

Os pesos iniciais das raridades continuam em 60:25:10:4:1 (Normal, Rara, Épica, Lendária e Mítica). Dentro de cada raridade, as cartas elegíveis têm chances iguais. Uma raridade conserva seu peso enquanto tiver pelo menos uma carta elegível; quando todas as suas cartas chegam ao máximo, seu peso é removido e os restantes são normalizados. A loja mostra as chances efetivas da próxima abertura.

Após nove aberturas sem épica ou superior, o sorteio usa apenas as raridades Épica, Lendária e Mítica ainda elegíveis, com pesos 10:4:1 normalizados. Receber épica ou superior zera a contagem. Se todas essas cartas já estiverem no máximo, as aberturas continuam evoluindo normais e raras; a contagem fica limitada a nove e a interface informa essa situação. Se todas as 15 cartas estiverem no máximo, a compra fica indisponível e nenhuma moeda é gasta.

## Progresso existente

O save v6 usa `collection` como mapa de ID para nível (1–5). Saves v5 convertem a quantidade obtida em nível: 1 cópia vira nível 1; 3 viram nível 3; 5 ou mais viram nível 5. IDs descobertos, equipamentos, IP, garantia, XP e outros progressos são preservados. As versões v1–v4 continuam aceitas pelas migrações anteriores. Saves v6 rejeitam níveis fora de 1–5.

O modo de teste continua começando com 300 IP, XP ilimitado e sem carregar/gravar progresso. Nenhum novo APK acompanha esta alteração do código-fonte.

## Validação da recuperação — 05/11/2026

Base local atualizada de `8e19839` para `df6694f` por fast-forward; `main` e `work` no remoto consultado apontavam para `df6694f`. Mudanças recuperadas do histórico do chat, com estrelinhas desenhadas adicionadas na coleção e na revelação, seguindo a orientação `game-dev` preservada no histórico.

Dois testes automatizados executados no Godot 4.6.3, em modo headless, após importar os recursos com `godot --headless --editor --path game --import`:

- `godot --headless --path game --script res://tests/test_cards.gd`: 2.105 verificações, zero falhas. Cobre compra, evolução, bônus, cartas no máximo, garantia, migração, persistência e reversão após falha de salvamento.
- `godot --headless --path game --script res://tests/test_mobile_ui.gd`: 341 verificações, zero falhas. Cobre abertura, virada completa sem pular, pular sem cobrar de novo, estrelas na coleção/revelação, bloqueio da coleção completa, quatro tamanhos de tela do modal e reinício durante a animação.

A primeira tentativa da interface precisou da importação da imagem do mapa. Após importá-la, foi corrigida a ordem de uma asserção do teste (nível 1 era conferido depois de apresentar nível 5) e a execução passou. Sem avaliação visual em tela ou instalação em aparelho Android nesta etapa; o APK v0.11 não foi reexportado.
