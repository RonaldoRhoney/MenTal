# MENTAL — AUDIO_FEEDBACK.md

Status: aprovado por Rhoney (dono). Parte oficial da Foundation, adicionado
durante a V2. Complementa `DESIGN_SYSTEM.md` — feedback sonoro segue a
mesma lógica semântica já aplicada a cor (reforço positivo discreto, nunca
punitivo ou agressivo).

## 1. Princípio

Som reforça o que a interface já comunica visualmente — nunca é a única
fonte de informação, e nunca contradiz o tom do produto (não-humilhação,
Clareza Imediata). O usuário tem controle total sobre presença e volume do
som, sem exceção.

## 2. Onde o som entra

| Evento | Caráter do som | Nota |
|---|---|---|
| Resposta correta | Curto, agradável, satisfatório | Reforça o feedback visual teal/verde já existente |
| Resposta incorreta | Suave, neutro | Nunca "buzzer" agressivo ou cômico — mesma lógica do terracota suave visual, nunca soa como punição ou zombaria |
| Conquista de território | Destaque maior, celebratório | Momento de maior peso emocional do produto — som pode ser mais elaborado que o de acerto comum |
| Badge/conquista desbloqueada | Destaque maior, celebratório | Mesmo nível do território — reforça o sistema de conquistas recém-implementado |
| Level up | Celebratório | Marca progressão de forma perceptível |
| Streak mantido/protegido | Positivo, mais discreto que conquista | Reforço de hábito, não precisa ter o mesmo peso de uma conquista |
| Navegação/toque geral | Opcional, muito discreto | Pode ficar fora desta etapa sem perda — não é essencial ao produto |

Nenhum som deve ser estridente, longo, ou repetitivo a ponto de cansar em
uso contínuo (o jogador pode responder dezenas de desafios em uma sessão).

## 3. Controle do usuário — requisito não-negociável

- **Toggle geral on/off** para efeitos sonoros, acessível a partir da tela
  de Perfil/Configurações.
- **Controle de volume** dos efeitos, separado do volume geral do
  dispositivo (slider simples é suficiente).
- Preferência **persistida localmente no dispositivo** — não é dado de
  jogo, não precisa ir ao backend nem ao `DATA_MODEL.md`.
- O app **nunca toca som se o dispositivo estiver em modo silencioso ou
  vibração**, a menos que o usuário tenha explicitamente ativado som dentro
  do app por cima dessa configuração do sistema — mesmo padrão esperado de
  qualquer app respeitável no Android.

## 4. Acessibilidade

Som nunca é a única forma de comunicar um resultado. Todo evento sonoro
desta tabela já possui equivalente visual implementado (cor, ícone, texto)
— o som é reforço, nunca substituto. Isso cobre uso sem áudio (ambiente
público, dispositivo sem som, deficiência auditiva) sem perda de
informação funcional.

## 5. Escopo técnico

- Biblioteca sugerida: `audioplayers` (Flutter) ou equivalente maduro e
  gratuito — Claude Code deve confirmar a melhor opção compatível com o
  princípio Free-First antes de implementar.
- Arquivos de áudio devem ser curtos (idealmente <1s para efeitos comuns,
  poucos segundos para celebração de conquista) para não pesar o tamanho
  do app.
- Sem música de fundo contínua nesta etapa — apenas efeitos pontuais por
  evento. Música de fundo pode ser avaliada em etapa futura, não faz parte
  deste documento.

## 6. Papel de cada parte

- **Rhoney**: aprova o caráter geral dos sons quando o Claude Code
  apresentar as primeiras opções (não precisa aprovar arquivo por arquivo).
- **Claude (arquitetura)**: garante que o controle do usuário (Seção 3) e
  a acessibilidade (Seção 4) estão implementados antes de aprovar a etapa
  como concluída.
- **Claude Code**: implementa a biblioteca de áudio, os sons por evento
  conforme a tabela da Seção 2, e o painel de controle do usuário — testa
  em dispositivo real antes de considerar fechado (som é uma das poucas
  coisas que não se valida bem em ambiente Linux/Web headless).
