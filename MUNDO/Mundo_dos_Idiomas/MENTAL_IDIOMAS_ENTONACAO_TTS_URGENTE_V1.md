# MENTAL — Mundo dos Idiomas: Correção de Entonação no TTS + Reforço de Escuta Proporcional

**Status:** URGENTE. Prioridade de execução hoje (26/09/2026). Cobre dois problemas: (1) qualidade de entonação do TTS já em produção no Mundo dos Idiomas, (2) reforço do requisito de escuta proporcional já formalizado para o MENTAL LINGO (MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md).

---

## 1. Problema 1 — TTS lendo palavras/frases sem entonação natural

### 1.1 Sintoma relatado por Rhoney
O TTS do Mundo dos Idiomas (`flutter_edge_tts`, já em produção) está lendo palavras e frases de forma **rápida e sem entonação adequada**, prejudicando a compreensão do usuário. Exemplos citados:
- **"car"** (inglês) sendo lido de forma seca/neutra, sem a entonação natural de fala.
- **"I will"** sendo lido **rápido demais**, sem a cadência/ritmo natural de uma frase falada por um humano nativo.

### 1.2 O que precisa ser corrigido
- A leitura deve soar **natural e compreensível**, com entonação apropriada ao idioma (inglês, espanhol, francês, e os demais que forem adicionados no futuro) — não uma leitura mecânica, achatada ou apressada.
- Isso vale tanto para **palavras isoladas** quanto para **frases completas**.
- A velocidade "Normal" (já existente como uma das 3 opções — Normal/Rápido/Acelerado) deve ser, de fato, uma velocidade de fala natural e clara — não uma leitura já rápida por padrão. Se o problema relatado por Rhoney está ocorrendo mesmo na velocidade "Normal", isso é uma prioridade de correção imediata, pois indica que o parâmetro de velocidade configurado no `flutter_edge_tts` pode estar incorreto ou mal calibrado.

### 1.3 Investigação técnica sugerida
- Verificar os parâmetros de `rate` (velocidade) e `pitch` (tonalidade) configurados na integração atual do `flutter_edge_tts` — é possível que o valor de `rate` esteja configurado acima do natural mesmo para a opção "Normal".
- Verificar se o texto está sendo enviado ao TTS como texto simples (o que pode gerar leitura mais mecânica) ou se há suporte a SSML (Speech Synthesis Markup Language) na integração atual, que permite controlar pausas, ênfase e entonação de forma mais fina — se disponível no `flutter_edge_tts`, avaliar seu uso para melhorar a naturalidade da fala.
- Testar com as vozes específicas já configuradas para inglês, espanhol e francês, confirmando se o problema é geral (todas as vozes) ou específico de alguma delas.
- Comparar o resultado atual com o áudio de referência das próprias vozes neurais do Microsoft Edge (fonte do `flutter_edge_tts`) reproduzidas diretamente, para confirmar se a limitação é da integração no MENTAL ou do próprio serviço de voz.

## 2. Problema 2 — Reforço: tempo de escuta proporcional (já formalizado, reforçar execução)

Este ponto já foi formalizado em MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md (seção "Arquitetura a avaliar", atualizada em 25/09/2026) — Rhoney reforça hoje a importância de execução:

- O tempo de escuta do MENTAL LINGO **não pode ser um teto fixo curto determinado pelo app**.
- Deve ser **proporcional ao tempo real que o usuário leva para falar sua pergunta**, implementado por **detecção de silêncio sustentado** (o app continua ouvindo enquanto detecta fala, tolerando pausas naturais de respiração, e só encerra a captura ao detectar silêncio contínuo significativo).
- Um teto de segurança de duração máxima **bem alto** (poucos minutos) pode existir apenas como proteção técnica contra captura travada por bug — nunca interferindo no uso normal de uma pergunta falada, mesmo que ela leve 30 segundos ou mais.

## 3. Escopo técnico (a executar por Claude Code hoje)

- Corrigir a configuração de velocidade/entonação do `flutter_edge_tts` no Mundo dos Idiomas, garantindo leitura natural na velocidade Normal, para palavras isoladas e frases completas, em todos os idiomas já suportados.
- Investigar e aplicar suporte a SSML (se disponível na biblioteca) para melhorar entonação, caso a simples correção de `rate`/`pitch` não seja suficiente.
- Confirmar/implementar a lógica de escuta proporcional por detecção de silêncio no MENTAL LINGO, conforme já especificado em MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md.
- Testar manualmente com os exemplos citados por Rhoney ("car", "I will") antes de reportar conclusão, confirmando que a leitura agora soa natural e compreensível.

## 4. Prompt Claude Code (pronto para uso hoje)

Investigue e corrija dois problemas do Mundo dos Idiomas no MENTAL, com prioridade de execução hoje. Primeiro: o TTS (`flutter_edge_tts`) está lendo palavras e frases (ex.: "car", "I will") de forma rápida e sem entonação natural, mesmo na velocidade "Normal". Verifique os parâmetros de rate/pitch configurados, avalie suporte a SSML na biblioteca para melhorar prosódia, e corrija para que a leitura soe natural e compreensível em todos os idiomas suportados (inglês, espanhol, francês), tanto para palavras isoladas quanto frases completas. Teste com os exemplos citados antes de reportar. Segundo: confirme e, se necessário, implemente a lógica de tempo de escuta do MENTAL LINGO proporcional à fala real do usuário, via detecção de silêncio sustentado (tolerando pausas de respiração), sem teto fixo curto — mantendo apenas um teto de segurança alto contra captura travada, conforme já especificado em MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md. Reporte o diagnóstico e a correção aplicada para os dois pontos.

## 5. Critério de aceite

- Palavras isoladas e frases no Mundo dos Idiomas são lidas com entonação natural e compreensível na velocidade Normal, em todos os idiomas suportados.
- Exemplos "car" e "I will" testados manualmente e confirmados como corrigidos.
- Tempo de escuta do MENTAL LINGO confirmado como proporcional à fala real do usuário, sem corte prematuro.
