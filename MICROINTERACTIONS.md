# MENTAL — MICROINTERACTIONS.md

Status: aprovado por Rhoney (dono). Substitui a implementação isolada de
`AUDIO_FEEDBACK.md` — este documento une som e microanimação visual como
uma única camada de feedback multissensorial, a ser implementada de forma
coesa, em uma etapa própria (não retrofit incremental espalhado por PRs
separados). `AUDIO_FEEDBACK.md` permanece válido como referência de regras
de áudio (Seções 2-5 dele são reaproveitadas aqui); este documento adiciona
a camada visual e formaliza que as duas devem nascer juntas.

## 1. Origem — por que este documento existe

Rhoney observou, ao ver a tela de resultado de acerto em uso real, que o
app "está muito estático" — visualmente correto (cor, hierarquia, texto)
mas sem nenhum momento de celebração sensorial. O `DESIGN_SYSTEM.md` §4 já
previa "microanimação leve" na celebração de acerto, mas isso nunca foi
implementado — esta é a lacuna que este documento fecha, junto com o áudio
que também nunca saiu do papel.

## 2. Princípio

Celebração reforça o que a interface já comunica — nunca é ruído visual
constante, nunca compromete a Clareza Imediata, nunca é a única forma de
transmitir um resultado (acessibilidade), e nunca produz qualquer efeito
negativo/punitivo em caso de erro (não-humilhação).

## 3. Calibração por evento — nem tudo merece o mesmo nível de festa

| Evento | Intensidade | Visual | Som (ref. `AUDIO_FEEDBACK.md`) |
|---|---|---|---|
| Acerto comum de desafio | Sutil | Pulso de brilho no card / pequena partícula rápida (<1s), não interrompe o ritmo de seguir para o próximo desafio | Curto, agradável |
| Erro | Nenhuma celebração | Sem animação negativa — permanece neutro | Suave, neutro |
| Conquista de território | Forte | Confete/celebração cheia, pode pausar a tela por um instante para o momento ser sentido | Destaque maior, celebratório |
| Badge desbloqueado | Forte | Mesmo peso de território | Destaque maior, celebratório |
| Level up | Forte | Celebração perceptível, mesma família visual de território/badge | Celebratório |
| Streak mantido/protegido | Moderada | Mais discreta que conquista — reforço de hábito, não pico emocional | Positivo, discreto |

Regra geral: "sutil" em eventos frequentes (acerto comum acontece dezenas
de vezes por sessão — celebração grande aqui cansa e vira ruído); "forte"
reservado para eventos raros e significativos (território, badge, nível).

## 4. Acessibilidade — requisito não-negociável

- Toda microanimação deve checar a preferência de sistema **"reduzir
  movimento"** do Android (`MediaQuery.disableAnimations` no Flutter, ou
  equivalente) — quando ativada, o app substitui a animação por uma versão
  estática equivalente (ex.: só a mudança de cor, sem partícula/movimento).
  Não é opcional: pessoas com sensibilidade a movimento (comum também em
  parte do público idoso) não podem ser forçadas a ver animação.
- Nenhum evento desta tabela depende exclusivamente de animação ou som para
  ser compreendido — texto e cor (já implementados) continuam sendo a
  fonte primária de informação; multissensorial é reforço, nunca requisito.
- Controle de som já definido em `AUDIO_FEEDBACK.md` §3 (toggle on/off,
  volume, respeito ao modo silencioso do dispositivo) continua valendo
  integralmente.

## 5. Sincronia entre som e visual

Quando ambos existirem para o mesmo evento (ex.: conquista de território),
disparo de som e animação deve ser simultâneo, não dessincronizado — a
experiência de celebração é uma coisa só, percebida em conjunto, não dois
efeitos que competem ou se atropelam.

## 6. Escopo técnico

- Biblioteca de animação: Flutter já oferece `AnimatedContainer`,
  `Hero`, e pacotes maduros de partícula/confete (ex.: `confetti`) —
  Claude Code deve propor a opção mais simples e leve (app não deve crescer
  muito de tamanho por causa de efeito visual).
- Reaproveitar a mesma biblioteca de áudio já escolhida em
  `AUDIO_FEEDBACK.md` §5.
- Implementação deve cobrir os eventos da tabela da Seção 3 de forma
  completa nesta etapa — não implementar "só acerto" e deixar território/
  badge/nível para depois; é exatamente esse fatiamento que o documento
  original de áudio pediu para evitar.

## 7. Quando implementar

Logo após o fechamento do item 4 da V2 (Desafios visuais) — não antes,
para que os eventos de todos os tipos de desafio (incluindo os 3 novos:
Enigmas, Textos, Visual) já estejam estáveis antes de desenhar a camada de
celebração sobre eles. Não é retrofit incremental disperso — é uma etapa
própria, testada como experiência coesa, mesma disciplina de todo o
projeto até aqui.

## 8. Papel de cada parte

- **Rhoney**: aprovou a observação original que originou este documento;
  valida a sensação final em dispositivo real antes de considerar fechado
  (celebração é uma das coisas que só se avalia por sensação humana, não
  por teste automatizado).
- **Claude (arquitetura)**: garante que a Seção 4 (acessibilidade) e a
  Seção 3 (calibração por evento, evitando saturação) são respeitadas
  antes de aprovar a etapa como concluída.
- **Claude Code**: implementa som e animação juntos, cobre todos os
  eventos da tabela, testa em dispositivo real (não valida bem em
  ambiente headless), e confirma que a preferência de "reduzir movimento"
  do sistema é respeitada.
