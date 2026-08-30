# MENTAL — Auditoria Estrutural: Conteúdo no Lugar Certo (Mundos, Territórios, Relâmpagos)

**Status:** Aprovado para execução imediata.
**Tipo:** Auditoria/varredura — não é para corrigir nada automaticamente. É para reportar cada inconsistência encontrada, para Rhoney decidir a correção item a item, mesmo padrão já usado no CHECKLIST_GOOGLE_PLAY_COMPLIANCE.md.

---

## 1. Objetivo

Com o volume grande de conteúdo curado recentemente (Mitologia, ENEM, Concursos, Tecnologia, Vida Prática, Curiosidade Relâmpago, e mais), existe risco real de algum item ter sido alocado no território/mundo/bloco errado — seja por erro de digitação no campo de categoria, seja por um item ter sido colado no arquivo errado durante a montagem. Esta auditoria verifica se cada pergunta/desafio/Relâmpago está de fato no lugar estrutural correto, e não apenas se o conteúdo em si está correto (isso já foi validado antes).

Em outras palavras: não é sobre "essa pergunta está certa?", é sobre "essa pergunta está no lugar certo?".

## 2. O que verificar, especificamente

### 2.1 Consistência entre Mundo → Território → Item
- Para cada Mundo existente no app (ex: Mundo da Linguagem, Mundo da Mente Lógica, e os novos blocos da V3), confirmar que todos os territórios vinculados a ele pertencem tematicamente a esse Mundo, sem nenhum território "encaixado" no lugar errado.
- Para cada Território (ex: mitologia_grega, tecnologia_fronteira, concursos_direito), confirmar que todo item de conteúdo dentro dele pertence de fato àquele assunto — ou seja, abrir cada arquivo/tabela de conteúdo e checar se, por exemplo, não existe uma pergunta sobre computação dentro de mitologia_grega, ou uma pergunta sobre folclore brasileiro dentro de tecnologia_seguranca.

### 2.2 Campos de categoria/metadado como fonte da verdade
- Verificar se o campo que identifica o território de cada item (ex: sub_bloco, territorio, ou equivalente usado no schema real do backend) está de fato preenchido corretamente em cada item, e não apenas assumido pela posição no arquivo.
- Reportar qualquer item cujo campo de categoria não bate com o conteúdo real da pergunta (ex: um item com sub_bloco "financas_pessoais" mas cuja pergunta é, na verdade, sobre filosofia).

### 2.3 Duplicação cruzada entre blocos
- Verificar se não existe o mesmo item de conteúdo (ou uma variação muito próxima da mesma pergunta) duplicado em mais de um território/bloco — isso não é "conteúdo no lugar errado" no sentido estrito, mas é uma inconsistência estrutural do mesmo tipo, e deve ser reportada junto.

### 2.4 Relâmpago especificamente
- Confirmar que todo desafio marcado como formato Relâmpago (timer curto, múltipla escolha) está de fato dentro de um território que faz sentido para esse formato — por exemplo, um item do bloco Curiosidade Relâmpago (V3.5) não deveria aparecer dentro de um território de outro bloco (ex: dentro de concursos_direito), e vice-versa.
- Confirmar que nenhum item de Pausa para Aprender (sem timer, sem múltipla escolha) está classificado incorretamente como Relâmpago, e vice-versa.

### 2.5 IDs e nomenclatura
- Verificar se o prefixo/padrão de ID de cada item (ex: mito-grega-, tec-front-, curio-) corresponde de fato ao território onde o item está armazenado — um ID com prefixo de um território, mas fisicamente presente no arquivo/tabela de outro território, é um forte indício de erro de alocação e deve ser reportado com prioridade.

## 3. Como reportar

Mesmo formato já usado em auditorias anteriores — para cada inconsistência encontrada:

[LOCAL ENCONTRADO]: onde está hoje (mundo/território/arquivo/linha ou ID)
[DEVERIA ESTAR EM]: onde pertence de fato, pelo conteúdo real do item
[EVIDÊNCIA]: trecho da pergunta/conteúdo que comprova a inconsistência
[AÇÃO NECESSÁRIA]: mover, corrigir campo de categoria, ou remover duplicata (não executar ainda — apenas propor)

Se nenhuma inconsistência for encontrada em uma seção da varredura, reportar explicitamente "Nenhuma inconsistência encontrada em [seção]" — não deixar a ausência de problema implícita, para que Rhoney saiba que aquela parte foi de fato verificada.

## 4. O que NÃO fazer nesta rodada

- Não mover, corrigir ou apagar nenhum item automaticamente.
- Não alterar nenhum campo de categoria sem aprovação prévia.
- Esta é uma auditoria de diagnóstico — a correção vira uma tarefa separada, item a item, depois que Rhoney revisar o relatório.

## 5. Entregável esperado

Um relatório único, organizado por Mundo → Território, listando:
1. Total de itens verificados em cada território.
2. Quantas inconsistências foram encontradas (se houver), no formato da seção 3.
3. Um resumo final indicando se a estrutura geral está íntegra ou se há necessidade de correção prioritária antes de qualquer nova carga de conteúdo futuro.
