# MENTAL — BUGS ENCONTRADOS EM TESTE REAL (Vertical Slice 01)

Status: reportado por Rhoney a partir de teste real no celular físico
(Moto G22), telas de "Palavras" — ver prints anexados na conversa original.
Este documento existe para não depender de mensagem de chat como única
fonte de registro, e para servir de referência caso um bug do mesmo padrão
volte a aparecer em outro tipo de desafio (Números, Lógica, Conhecimentos).

## Bug 1 — Resposta correta na primeira tentativa não é reconhecida

**Como foi observado:** ao digitar a resposta certa ("CASAL") na primeira
tentativa, sem ter pedido nenhuma dica, o app não reconheceu como correta
nem avançou para a tela de resultado. Só funcionou depois de pedir as 2
dicas disponíveis e reenviar a resposta.

**Por que isso é bug, não comportamento esperado:** viola diretamente o
Princípio de Justiça de Resultado (`PRODUCT_PRINCIPLES.md`) — resposta
certa deve ser reconhecida imediatamente, independente de quantas dicas
foram usadas antes, inclusive zero. Não existe (nem deveria existir)
nenhuma regra que condicione o reconhecimento de acerto a um número mínimo
de tentativas ou dicas usadas.

**Hipóteses técnicas a investigar (não confirmadas, para orientar
diagnóstico, não para prescrever a causa):**
- Bug de estado/clique na UI Flutter: o botão "Confirmar resposta" pode não
  estar disparando a chamada de API corretamente no primeiro clique.
- Bug no client: backend pode ter validado corretamente, mas a tela não
  atualizou para "Você acertou!" — nesse caso o dado em `attempts` estaria
  certo, e o bug seria isolado ao client.
- Menos provável, mas a descartar: alguma diferença de comparação entre a
  primeira tentativa e tentativas subsequentes no backend.

**Ação:** Claude Code deve identificar a causa raiz exata (client ou
backend) antes de aplicar correção, e reportar qual das hipóteses acima (ou
outra) era a real.

## Bug 2 — Comparação de resposta deveria ser case-insensitive e tolerar espaços

**Como foi observado:** não é um erro pontual, é um requisito faltante —
identificado ao revisar o comportamento de validação de resposta.

**Requisito correto:** a validação de resposta no backend deve normalizar
antes de comparar:
- Case-insensitive: "casal", "CASAL", "Casal" devem todas ser aceitas como
  a mesma resposta correta.
- Tolerância a espaços em branco nas pontas: " casal " deve ser tratado
  igual a "casal" (comum em digitação mobile, toque acidental de espaço).

**Por que isso tem que estar no backend, não no client:** mesma regra já
aplicada a Score/XP/desbloqueio — o backend é a única autoridade. Se a
normalização existisse só no Flutter, alguém manipulando a chamada de API
diretamente poderia contornar a validação enviando formatação "diferente"
de propósito. A normalização precisa estar no ponto real de validação, no
FastAPI.

**Ação:** Claude Code deve confirmar se isso já existe na função de
comparação atual (é possível que a causa do Bug 1 e a ausência desta
normalização estejam na mesma função) e implementar/corrigir junto.

## Relação entre os dois bugs

Ambos apontam para a mesma função de comparação de resposta no backend.
É provável (não confirmado) que investigar o Bug 1 revele também a causa
do Bug 2, ou vice-versa. Recomenda-se investigar e corrigir os dois juntos,
com um teste automatizado novo cobrindo especificamente: resposta exata na
primeira tentativa, resposta em caixa diferente, e resposta com espaço
extra — para este bug (ou variação dele) não voltar a passar despercebido
em nenhum dos 4 tipos de desafio (Palavras, Números, Lógica, Conhecimentos
gerais), não só em Palavras onde foi observado.

## Diagnóstico e resolução (Claude Code, 2026-08-20)

**Bug 1 — causa raiz confirmada: client Flutter, hipótese 1 do documento.**
`lib/screens/challenge_screen.dart`, campo de texto usado em desafios sem
múltipla escolha: `onChanged: (value) => _selectedOption = value` **sem
`setState()`**. Em Flutter, mutar uma variável sem `setState()` não força
redesenho — o botão "Confirmar resposta"
(`onPressed: _selectedOption == null ? null : _submitAnswer`) continuava
lendo o valor da última renderização (`null`) e ficava desabilitado, mesmo
com a resposta certa já digitada. Só quando outro evento chamava
`setState()` (pedir dica) a tela redesenhava e finalmente refletia o valor
já digitado — exatamente o sintoma relatado ("só funcionou depois de pedir
as 2 dicas"). Corrigido: `onChanged` agora envolve a atribuição em
`setState()`. Prova de que é regressão real, não suposição: o teste
`client/test/challenge_screen_regression_test.dart` foi rodado contra o
código antigo (falhou, reproduzindo o bug) e contra o código corrigido
(passou).

**Bug 2 — não era um bug ativo; a normalização já existia no backend**
(`submitted_answer.strip().lower() == correct_answer.strip().lower()`,
`routers/challenges.py`). A aparência de falha vinha inteiramente do Bug 1
mascarando qualquer tentativa de resposta correta na primeira tentativa —
sem o botão funcionar, nenhuma variação de maiúscula/espaço chegava a ser
testada de verdade. Travado com teste de regressão explícito
(`backend/tests/test_answer_normalization_regression.py`), parametrizado
nos 4 territórios (Palavras, Números, Lógica, Conhecimento): resposta
correta na 1ª tentativa sem dica, maiúscula, minúscula, espaço nas pontas
— 12 casos, todos passando.

## Papel de cada parte

- **Rhoney**: reportou o comportamento observado em teste real.
- **Claude (arquitetura)**: registra formalmente, orienta hipóteses de
  diagnóstico, e deve validar a causa raiz explicada pelo Claude Code antes
  de considerar o bug fechado.
- **Claude Code**: identifica a causa raiz real (não só aplica correção
  sem entender a origem), corrige, adiciona teste automatizado de
  regressão para os dois comportamentos, e confirma nos 4 tipos de
  desafio, não apenas em Palavras.
