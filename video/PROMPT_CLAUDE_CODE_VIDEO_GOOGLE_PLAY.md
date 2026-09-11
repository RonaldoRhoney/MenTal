# MENTAL — Vídeo de Orientação de Uso para a Ficha do Google Play

**Status:** Aprovado para implementação.
**Documento separado e independente** de REORGANIZACAO_MENUS_HOME_V1.md — não deve ser combinado com aquele documento.
**Referência visual:** as 13 capturas de tela reais do app já compartilhadas (Home, Feed, Movimento nos 4 períodos, Amigos, Ranking, Batalhas, Meu Perfil), mostrando o fluxo real de navegação a ser roteirizado.

---

## 1. Objetivo

Criar um vídeo curto de orientação de uso do MENTAL, destinado a aparecer na ficha do aplicativo na Google Play, para que a pessoa que está prestes a baixar o app já entenda, antes mesmo de instalar, como a experiência funciona — reduzindo a sensação de "não sei o que estou baixando" e aumentando a confiança na hora de decidir instalar.

## 2. Ressalva importante sobre o que é tecnicamente possível nesta entrega

O Claude Code consegue: roteirizar o vídeo, preparar uma conta de teste com dados reais e "bonitos" (XP, streak, MentalCoins, histórico de Movimento preenchido, como já usado no processo de captura de screenshots), gravar a tela do app em vídeo (usando gravação de tela nativa do Android) percorrendo o roteiro definido, e editar/montar esse material bruto num vídeo final coeso, com cortes e eventualmente texto de apoio.

O Claude Code **não consegue**: publicar esse vídeo diretamente na ficha da Google Play. A Google exige que o vídeo promocional de uma ficha de app seja um link do YouTube, inserido manualmente através do Play Console — uma ação que depende do acesso de Rhoney à conta de desenvolvedor, não algo que possa ser automatizado por esta tarefa. Esta entrega produz o vídeo pronto; o upload ao YouTube e a vinculação na ficha da Google Play são passos finais que cabem a Rhoney.

## 3. Roteiro sugerido, com base nas 13 telas de referência

O vídeo deve seguir uma jornada lógica de apresentação, não uma sequência aleatória de telas. Ordem sugerida:

1. **Abertura na Home** — mostrar o card de identidade (nível, XP, MentalCoins, streak) e o grid de atalhos, dando a primeira impressão de "o que é isto".
2. **Mundos disponíveis** — percorrer rapidamente a lista de Mundos (Linguagem, Mente Lógica, Cultura Geral, Descoberta, Idiomas, e demais), transmitindo a variedade de conteúdo sem se aprofundar em nenhum ainda.
3. **Ranking** — mostrar a lista com badges de conquista de cada jogador (streak, Mundos completos, troféus, MentalCoins, passos), destacando que o progresso é comparável ao de outros jogadores.
4. **Movimento** — demonstrar a tela com os 4 períodos (Hoje/Semana/Mês/Ano), o gráfico de sessões do dia e o histórico acumulado, mostrando que o app also recompensa atividade física real.
5. **Amigos** — mostrar como adicionar um amigo pelo código e o botão de desafiar.
6. **Batalhas** — mostrar o histórico de resultados contra amigos, reforçando o aspecto competitivo/social.
7. **Feed** — mostrar a tela (mesmo que ainda vazia na captura de referência), explicando por texto de apoio que ali aparecem as conquistas de amigos e de quem o jogador segue.
8. **Encerramento** — voltar à Home, com uma chamada final convidando a pessoa a experimentar o app.

## 4. Estilo e tom do vídeo

- Tom acolhedor e direto, sem jargão técnico — o público-alvo é alguém que ainda não conhece o app.
- Se incluir texto de apoio sobre as telas (legendas ou callouts), manter frases curtas, no mesmo tom já usado na identidade do MENTAL ("Mental é quem conquista com a mente").
- Duração recomendada: entre 20 e 40 segundos, alinhado ao padrão de vídeos promocionais de ficha de app na Google Play, que costumam ser curtos.
- Preservar a paleta de cores e identidade visual já estabelecida do app durante toda a gravação — não é necessário adicionar elementos gráficos extras além do que já existe na interface real.

## 5. Escopo técnico (alto nível — a propor em detalhe por Claude Code)

- Preparar uma conta de teste com dados de exemplo realistas e visualmente ricos (nível alto, XP significativo, streak ativo, histórico de Movimento com múltiplos dias, ao menos um amigo adicionado, ao menos uma Batalha no histórico) antes de iniciar a gravação — evitando que o vídeo mostre telas vazias ou com "zero" em tudo.
- Usar gravação de tela nativa do Android (ex.: `adb shell screenrecord` ou equivalente) para capturar cada trecho do roteiro da seção 3.
- Editar e unir os trechos gravados (ex.: usando ffmpeg) na ordem definida, aplicando cortes suaves entre uma tela e outra.
- Adicionar textos de apoio/legendas, se optar por incluí-los, de forma consistente com a identidade visual do app.
- Exportar o vídeo final em formato e resolução compatíveis com upload ao YouTube (pré-requisito da Google Play para vídeo de ficha).

## 6. Critério de aceite

- Vídeo final produzido, seguindo a ordem de roteiro da seção 3, com duração entre 20 e 40 segundos.
- Dados de exemplo usados na gravação são realistas e visualmente representativos do app em uso real, não telas vazias.
- Identidade visual do app preservada durante toda a gravação, sem elementos externos que destoem do restante da marca.
- Vídeo entregue como arquivo pronto para upload manual ao YouTube por Rhoney — esta entrega não inclui a publicação na ficha da Google Play em si, conforme ressalva da seção 2.
