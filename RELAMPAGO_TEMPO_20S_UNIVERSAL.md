# MENTAL — Padronização do Tempo de Resposta Relâmpago para 20 Segundos

**Status:** Aprovado para implementação.
**Escopo:** Aplica-se a TODOS os desafios no formato Relâmpago do MENTAL, em qualquer território/bloco/dificuldade já existente ou futuro. Não é uma regra nova só para conteúdo futuro — é correção retroativa de todo o conteúdo já curado.

---

## 1. Motivo

O tempo de resposta atual varia por território/dificuldade (tipicamente entre 10 e 16 segundos, conforme os arquivos de conteúdo já entregues). Com o volume de conteúdo gerado nas fases V3.1 a V3.5, muitas perguntas ficaram mais longas do que as charadas curtas para as quais o tempo original foi calibrado — usuários não têm tempo suficiente para ler o enunciado inteiro antes de responder, mesmo sabendo a resposta.

## 2. Nova regra

- **Todo desafio Relâmpago passa a ter janela única de 20 segundos**, substituindo os valores variados usados até hoje (10s, 12s, 14s, 15s, 16s, etc.).
- Essa mudança vale tanto para o **teto máximo de tempo disponível** quanto para a base de cálculo do bônus de velocidade (ver seção 3).
- Aplica-se a todos os territórios já implementados (Mitologia, ENEM, Concursos, Tecnologia, Vida Prática, Curiosidade Relâmpago, Libras) e a todos os futuros.

## 3. Mecânica de recompensa (reforço, sem mudança de princípio)

O princípio de bônus de velocidade já existente permanece o mesmo — apenas a janela de tempo em que ele é calculado passa a ser maior:

- Quanto mais rápido o usuário responder corretamente, dentro da janela de até 20 segundos, maior o bônus de XP.
- Resposta correta no início da janela (ex.: primeiros segundos) deve gerar o bônus máximo; resposta correta perto do fim dos 20 segundos deve gerar bônus mínimo ou nenhum, seguindo a mesma curva/fórmula de cálculo de velocidade já implementada hoje — não é necessário redesenhar a fórmula, apenas recalibrar sua escala para o novo teto de 20s.
- Timeout (usuário não responde dentro dos 20 segundos) mantém o mesmo comportamento de soft timeout já definido em PALAVRAS_RELAMPAGO.md — não zera o desafio, apenas encerra a chance de resposta sem bônus.

## 4. Escopo técnico

- **Correção de dado, não só de regra futura**: todo campo `tempo_segundos` (ou equivalente) nos arquivos de conteúdo já entregues e já carregados em produção deve ser atualizado para 20, em todos os territórios Relâmpago, independente da dificuldade.
- **Configuração central, não valor espalhado**: se o valor de tempo estiver hoje hardcoded por item individual em vez de vir de uma constante/configuração central do formato Relâmpago, esta é uma boa oportunidade de corrigir a arquitetura — centralizar o tempo padrão numa única constante de configuração, evitando que uma futura mudança de tempo precise, de novo, editar centenas de itens um por um.
- **Curiosidade Relâmpago (V3.5)** e **Libras** seguem a mesma regra — nenhuma exceção de território.
- Autoridade do cronômetro e do cálculo de bônus permanece 100% no backend, como já é hoje — o valor de 20s não deve ser apenas um número exibido no cliente, deve ser a referência real usada no cálculo de XP.

## 5. O que NÃO muda

- A mecânica de soft timeout permanece igual.
- A fórmula/lógica de cálculo do bônus de velocidade permanece a mesma em princípio — só a escala de tempo em que ela opera aumenta de (10-16s) para 20s.
- Territórios que não são Relâmpago (ex.: Pausa para Aprender, que já não tem timer) não são afetados por esta mudança.

## 6. Critério de aceite

- Todo desafio Relâmpago, em qualquer território, exibe e aplica janela de 20 segundos.
- Bônus de velocidade recalibrado para a nova janela, mantendo o princípio "quanto mais rápido, maior o bônus".
- Nenhum item de conteúdo já carregado em produção ficou com tempo antigo (10-16s) por omissão da correção retroativa.
- Testes automatizados existentes relacionados a tempo/timeout/bônus de velocidade atualizados para refletir a nova janela, sem quebrar cobertura.
