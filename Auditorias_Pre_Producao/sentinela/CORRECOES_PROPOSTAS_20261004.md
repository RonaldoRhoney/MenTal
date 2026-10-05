# MENTAL — Sentinela: Correções Propostas (04/10/2026)

Gerado a partir de `backend/scripts/sentinela.py` (varredura completa, 0 correções mecânicas, 59 na fila de conteúdo). Nenhuma correção abaixo foi aplicada ao banco — tudo aguardando aprovação, conforme AGENTE_SENTINELA_CONTEUDO_V1.md §4.2.

**Total: 59 itens.** Todas as correções abaixo foram revalidadas programaticamente contra a mesma regra de detecção da Sentinela — nenhuma delas volta a disparar o achado.

## Como aprovar
Revise por categoria. Pode aprovar uma categoria inteira de uma vez (ex.: "aprovado o grupo 1") ou pedir ajuste em itens específicos pelo `challenge_id`.

## Grupo 1 — Palavras cognatas em Idiomas (29 itens)
O enunciado citava a palavra em português entre aspas, e para palavras cognatas (grafia igual/quase igual entre português e o idioma-alvo) isso entregava a resposta. Correção: trocar a citação direta por uma definição em português, mantendo opções, resposta, explicação e dicas originais intactas.

### espanhol_avancado · `b68ecd04`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'negociar' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'negociar' em espanhol?
- **Depois:** Como se escreve, em espanhol, o verbo que significa fazer um acordo comercial sobre preço ou condições?
- *(resposta correta 'Negociar' continua igual, sem alteração)*

### espanhol_avancado · `b53006ce`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'a menos que' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'a menos que' novamente para fixar em espanhol?
- **Depois:** Como se escreve, em espanhol, a expressão condicional que introduz uma exceção, equivalente a 'exceto se'?
- *(resposta correta 'A menos que' continua igual, sem alteração)*

### espanhol_avancado · `32608d63`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'antes de (prazo)' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'antes de' (prazo) em espanhol?
- **Depois:** Como se escreve, em espanhol, a expressão que indica que algo deve acontecer anteriormente a um prazo?
- *(resposta correta 'Antes de' continua igual, sem alteração)*

### espanhol_avancado · `54e90e32`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'diferente' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'diferente' em espanhol?
- **Depois:** Como se escreve, em espanhol, o adjetivo que indica que algo não é igual a outra coisa?
- *(resposta correta 'Diferente' continua igual, sem alteração)*

### espanhol_avancado · `85f9b569`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'confirmar' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'confirmar' em espanhol?
- **Depois:** Como se escreve, em espanhol, o verbo que significa validar ou reafirmar algo como certo?
- *(resposta correta 'Confirmar' continua igual, sem alteração)*

### espanhol_avancado · `50de073a`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'ofendido(a)' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'ofendido(a)' em espanhol?
- **Depois:** Como se escreve, em espanhol, o adjetivo que descreve alguém que se sentiu magoado por um comentário ou atitude?
- *(resposta correta 'Ofendido' continua igual, sem alteração)*

### espanhol_avancado · `3dc22f92`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'a menos que' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'a menos que' novamente para fixar (condicional) em espanhol?
- **Depois:** Como se escreve, em espanhol, a expressão condicional que introduz uma exceção, equivalente a 'exceto se'?
- *(resposta correta 'A menos que' continua igual, sem alteração)*

### espanhol_avancado · `76bed4cc`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'permanece' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'permanece' em espanhol?
- **Depois:** Como se escreve, em espanhol, a forma verbal que indica que algo continua no mesmo estado?
- *(resposta correta 'Permanece' continua igual, sem alteração)*

### espanhol_basico · `91197694`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'grande' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'grande' em espanhol?
- **Depois:** Como se escreve, em espanhol, o adjetivo que indica tamanho elevado?
- *(resposta correta 'Grande' continua igual, sem alteração)*

### espanhol_basico · `323c974c`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'camisa' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'camisa' em espanhol?
- **Depois:** Como se escreve, em espanhol, a peça de roupa usada na parte de cima do corpo, geralmente com botões?
- *(resposta correta 'Camisa' continua igual, sem alteração)*

### espanhol_basico · `22b96b2d`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'rápido' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'rápido' em espanhol?
- **Depois:** Como se escreve, em espanhol, o adjetivo que indica velocidade elevada?
- *(resposta correta 'Rápido' continua igual, sem alteração)*

### espanhol_basico · `cabae8de`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'triste' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'triste' em espanhol?
- **Depois:** Como se escreve, em espanhol, o adjetivo que descreve quem está com o humor abatido, melancólico?
- *(resposta correta 'Triste' continua igual, sem alteração)*

### espanhol_basico · `a7ab1b3a`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'porque' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'porque' em espanhol?
- **Depois:** Como se escreve, em espanhol, a conjunção usada para explicar uma causa ou motivo?
- *(resposta correta 'Porque' continua igual, sem alteração)*

### espanhol_basico · `9a6830a8`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'por favor' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'por favor' em espanhol?
- **Depois:** Como se escreve, em espanhol, a expressão usada para pedir algo educadamente?
- *(resposta correta 'Por favor' continua igual, sem alteração)*

### espanhol_intermediario · `3e98be37`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'ocupado(a)' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'ocupado(a)' em espanhol?
- **Depois:** Como se escreve, em espanhol, o adjetivo que indica que alguém está sem tempo livre?
- *(resposta correta 'Ocupado' continua igual, sem alteração)*

### espanhol_intermediario · `94519a3d`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'terminar' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'terminar' em espanhol?
- **Depois:** Como se escreve, em espanhol, o verbo que significa concluir ou finalizar algo?
- *(resposta correta 'Terminar' continua igual, sem alteração)*

### espanhol_intermediario · `2fb04a4d`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'antes de' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'antes de' em espanhol?
- **Depois:** Como se escreve, em espanhol, a expressão que indica que algo acontece anteriormente a outra coisa?
- *(resposta correta 'Antes de' continua igual, sem alteração)*

### espanhol_intermediario · `897a2ea1`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'médico(a)' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'médico(a)' em espanhol?
- **Depois:** Como se escreve, em espanhol, o substantivo que indica o profissional formado em medicina?
- *(resposta correta 'Médico' continua igual, sem alteração)*

### espanhol_intermediario · `3d006b14`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'descansar' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'descansar' em espanhol?
- **Depois:** Como se escreve, em espanhol, o verbo que significa repousar ou relaxar?
- *(resposta correta 'Descansar' continua igual, sem alteração)*

### espanhol_intermediario · `a55a99fe`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'barato(a)' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'barato(a)' em espanhol?
- **Depois:** Como se escreve, em espanhol, o adjetivo que indica preço baixo?
- *(resposta correta 'Barato' continua igual, sem alteração)*

### espanhol_intermediario · `eec26116`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'devolver' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'devolver' em espanhol?
- **Depois:** Como se escreve, em espanhol, o verbo que significa entregar de volta algo emprestado ou comprado?
- *(resposta correta 'Devolver' continua igual, sem alteração)*

### espanhol_intermediario · `6fffb5c2`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'cancelar' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'cancelar' em espanhol?
- **Depois:** Como se escreve, em espanhol, o verbo que significa desfazer algo que estava planejado?
- *(resposta correta 'Cancelar' continua igual, sem alteração)*

### espanhol_intermediario · `6fb18f45`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'a menos que' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'a menos que' em espanhol?
- **Depois:** Como se escreve, em espanhol, a expressão condicional que introduz uma exceção, equivalente a 'exceto se'?
- *(resposta correta 'A menos que' continua igual, sem alteração)*

### espanhol_intermediario · `09257838`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'difícil' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'difícil' em espanhol?
- **Depois:** Como se escreve, em espanhol, o adjetivo que indica que algo exige esforço para ser feito ou entendido?
- *(resposta correta 'Difícil' continua igual, sem alteração)*

### espanhol_intermediario · `b720f866`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'entender' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'entender' em espanhol?
- **Depois:** Como se escreve, em espanhol, o verbo que significa compreender algo?
- *(resposta correta 'Entender' continua igual, sem alteração)*

### espanhol_intermediario · `80c0188d`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'explicar' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'explicar' em espanhol?
- **Depois:** Como se escreve, em espanhol, o verbo que significa tornar algo compreensível para outra pessoa?
- *(resposta correta 'Explicar' continua igual, sem alteração)*

### espanhol_intermediario · `7e62d2fc`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'antes de' se escreve igual/quase igual em português e espanhol, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'antes de' novamente para fixar em espanhol?
- **Depois:** Como se escreve, em espanhol, a expressão que indica que algo acontece anteriormente a outra coisa?
- *(resposta correta 'Antes de' continua igual, sem alteração)*

### frances_basico · `d62b0130`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'triste' se escreve igual/quase igual em português e francês, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'triste' em francês?
- **Depois:** Como se escreve, em francês, o adjetivo que descreve quem está com o humor abatido, melancólico?
- *(resposta correta 'Triste' continua igual, sem alteração)*

### ingles_avancado · `6553732f`
- **Campo:** prompt
- **Motivo:** palavra cognata — 'confirmar' se escreve igual/quase igual em português e inglês, então citar a palavra no enunciado já entrega a resposta
- **Antes:** Como se escreve 'confirmar' em inglês?
- **Depois:** Como se escreve, em inglês, o verbo que significa validar ou reafirmar algo como certo?
- *(resposta correta 'Confirm' continua igual, sem alteração)*

## Grupo 2 — Concordância Nominal (4 itens)
O parêntese final do enunciado repetia a palavra-base, idêntica à resposta correta (são todos casos de adjetivo invariável). Correção: remover o parêntese — as 4 alternativas já bastam pra testar a regra.

### linguagem_concordancia_nominal · `8fc1b58a`
- **Campo:** prompt
- **Motivo:** o parêntese final repete a palavra-base, que aqui é idêntica à resposta correta (adjetivo invariável) — as 4 alternativas já bastam pra testar a regra de concordância, sem precisar repetir a resposta
- **Antes:** Complete: O menino ___ chegou cedo. (cansado)
- **Depois:** Complete: O menino ___ chegou cedo.
- *(resposta correta 'cansado' continua igual, sem alteração)*

### linguagem_concordancia_nominal · `ff7a191f`
- **Campo:** prompt
- **Motivo:** o parêntese final repete a palavra-base, que aqui é idêntica à resposta correta (adjetivo invariável) — as 4 alternativas já bastam pra testar a regra de concordância, sem precisar repetir a resposta
- **Antes:** Complete: Ela é ___ inteligente. (bastante)
- **Depois:** Complete: Ela é ___ inteligente.
- *(resposta correta 'bastante' continua igual, sem alteração)*

### linguagem_concordancia_nominal · `66184d0c`
- **Campo:** prompt
- **Motivo:** o parêntese final repete a palavra-base, que aqui é idêntica à resposta correta (adjetivo invariável) — as 4 alternativas já bastam pra testar a regra de concordância, sem precisar repetir a resposta
- **Antes:** Complete: É ___ entrada de estranhos. (proibido)
- **Depois:** Complete: É ___ entrada de estranhos.
- *(resposta correta 'proibido' continua igual, sem alteração)*

### linguagem_concordancia_nominal · `1d10912c`
- **Campo:** prompt
- **Motivo:** o parêntese final repete a palavra-base, que aqui é idêntica à resposta correta (adjetivo invariável) — as 4 alternativas já bastam pra testar a regra de concordância, sem precisar repetir a resposta
- **Antes:** Complete: Comprei duas camisas ___. (azul-marinho)
- **Depois:** Complete: Comprei duas camisas ___.
- *(resposta correta 'azul-marinho' continua igual, sem alteração)*

## Grupo 3 — Dica entrega a resposta (23 itens)
A 1ª dica nomeava diretamente a resposta (nome de pessoa, país ou evento). Correção: reescrever a dica mantendo uma pista real (ano, contexto, evento relacionado), sem citar a resposta.

### palavras · `3fef46b6`
- **Campo:** hints[1]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense em quantos alunos, ao todo, se destacaram no torneio.
- **Depois:** Pense em quantos alunos, ao todo, tiveram esse desempenho no torneio — isso define se o verbo vai para singular ou plural.

### internet_gigantes · `730747f8`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Google, Larry Page e Sergey Brin'.
- **Depois:** Pense nos dois fundadores, ambos ex-alunos de doutorado em Stanford.

### internet_gigantes · `193f402e`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Google, Larry Page e Sergey Brin'.
- **Depois:** Pense em quem ocupou o cargo antes de Eric Schmidt assumir como CEO em 2001.

### internet_gigantes · `6890dc63`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Google, Larry Page e Sergey Brin'.
- **Depois:** Pense em qual dos dois fundadores nasceu fora dos Estados Unidos e emigrou ainda criança.

### internet_gigantes · `6f643bbe`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Facebook e Mark Zuckerberg'.
- **Depois:** Pense no estudante de Harvard que criou a rede em seu dormitório universitário, em 2004.

### internet_sistemas_operacionais · `c70a93ec`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Linux e Linus Torvalds'.
- **Depois:** Pense no estudante finlandês que criou o sistema em 1991 como projeto pessoal.

### copa_mundo_era_moderna · `0dc62a44`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'França 1998 e a Consagração de Zidane'.
- **Depois:** Pense no ano: 1998, marcado pela consagração de Zidane.

### copa_mundo_era_moderna · `9bbe1a4d`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'França 1998 e a Consagração de Zidane'.
- **Depois:** Pense no ano: 1998, marcado pela consagração de Zidane.

### copa_mundo_era_moderna · `35797ca8`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Coreia/Japão 2002 e o Pentacampeonato Brasileiro'.
- **Depois:** Pense na Copa de 2002, disputada na Coreia do Sul e no Japão.

### copa_mundo_era_moderna · `24963632`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Rússia 2018 e o Título Histórico de Messi no Catar 2022'.
- **Depois:** Pense no ano: 2018, edição anterior ao título histórico de Messi no Catar, em 2022.

### copa_mundo_expansao · `49fadada`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Chile 1962 e o Bicampeonato Brasileiro'.
- **Depois:** Pense na Copa de 1962, disputada no Chile.

### copa_mundo_expansao · `7370e75e`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Inglaterra 1966 e o Gol Fantasma'.
- **Depois:** Pense no ano: 1966, marcado pelo episódio do Gol Fantasma.

### copa_mundo_expansao · `016be63f`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Inglaterra 1966 e o Gol Fantasma'.
- **Depois:** Pense no ano: 1966, marcado pelo episódio do Gol Fantasma.

### copa_mundo_expansao · `2bd677ee`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Inglaterra 1966 e o Gol Fantasma'.
- **Depois:** Pense na final de 1966, entre Inglaterra e Alemanha Ocidental, decidida na prorrogação.

### copa_mundo_expansao · `aebab3a2`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'México 1970 e o Tricampeonato Brasileiro'.
- **Depois:** Pense no ano: 1970, quando o Brasil conquistou seu tricampeonato mundial.

### copa_mundo_expansao · `97ff2862`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Argentina 1978 e Espanha 1982'.
- **Depois:** Pense no ano: 1978, quando o país-sede conquistou seu primeiro título mundial.

### copa_mundo_expansao · `11d2051e`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Argentina 1978 e Espanha 1982'.
- **Depois:** Pense no ano: 1982, a edição seguinte à de 1978 na Argentina.

### copa_mundo_expansao · `27baf701`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Itália 1990 e o Tetracampeonato Brasileiro em 1994'.
- **Depois:** Pense no ano: 1990, quatro anos antes do tetracampeonato brasileiro de 1994.

### copa_mundo_primeiras_copas · `db408ce3`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'A Copa de 1930 no Uruguai'.
- **Depois:** Pense na primeira edição da história da Copa do Mundo, em 1930.

### copa_mundo_primeiras_copas · `e1d57170`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'A Copa de 1930 no Uruguai'.
- **Depois:** Pense na primeira edição da história da Copa do Mundo, em 1930.

### copa_mundo_primeiras_copas · `480e8e54`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'O Maracanazo — Copa de 1950 no Brasil'.
- **Depois:** Pense na final da Copa de 1950, disputada no Maracanã, no Rio de Janeiro.

### copa_mundo_primeiras_copas · `69d770cd`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Suécia 1958 — A Estreia de Pelé e o Primeiro Título Brasileiro'.
- **Depois:** Pense no ano: 1958, marcado pela estreia de Pelé e o primeiro título brasileiro.

### copa_mundo_primeiras_copas · `8c95f1ef`
- **Campo:** hints[0]
- **Motivo:** a dica cita nominalmente a resposta correta (ou parte dela), entregando-a sem precisar responder
- **Antes:** Pense no tema: 'Suécia 1958 — A Estreia de Pelé e o Primeiro Título Brasileiro'.
- **Depois:** Pense no ano: 1958, marcado pela estreia de Pelé e o primeiro título brasileiro.

## Grupo 4 — Casos avulsos (3 itens)
Enunciado estruturado de um jeito que citava a resposta por outro caminho (nome do evento repetido nas alternativas, pergunta binária que já nomeia as duas opções). Correção: reformular o enunciado mantendo a mesma pergunta de fundo.

### enem_humanas · `46193cb4`
- **Campo:** prompt
- **Motivo:** o nome do evento ('Independência do Brasil') é também uma das 4 alternativas — a pergunta já entrega o nome oficial do processo
- **Antes:** Qual é o nome do processo histórico que oficializou a independência do Brasil em relação a Portugal, em 1822?
- **Depois:** O que Dom Pedro I proclamou às margens do rio Ipiranga, em 7 de setembro de 1822, rompendo o vínculo colonial com Portugal?
- *(resposta correta 'Independência do Brasil' continua igual, sem alteração)*

### tecnologia_fundamentos · `74804da8`
- **Campo:** prompt
- **Motivo:** a resposta ('Arquivo') é citada quase literalmente na descrição da própria pergunta
- **Antes:** Qual é o nome do arquivo digital que armazena fotos, vídeos ou documentos, organizados dentro do sistema do computador?
- **Depois:** Como se chama a unidade de dados digitais (como uma foto, vídeo ou documento) salva e organizada dentro do sistema de um computador?
- *(resposta correta 'Arquivo' continua igual, sem alteração)*

### internet_sistemas_operacionais · `cc554577`
- **Campo:** prompt
- **Motivo:** o enunciado já nomeia as duas alternativas possíveis ('código aberto ou fechado'), tornando a pergunta binária óbvia
- **Antes:** O Android é um sistema de código aberto ou fechado?
- **Depois:** Qual é a natureza do código-fonte do sistema operacional Android?
- *(resposta correta 'Código aberto' continua igual, sem alteração)*
