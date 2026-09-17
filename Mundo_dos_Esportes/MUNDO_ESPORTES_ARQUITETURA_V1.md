# MENTAL — Mundo dos Esportes: Arquitetura com SubMundos por Categoria

**Status:** APROVADO. Estrutura de dados a seguir estritamente — decisão de produto já tomada.
**Reaproveita:** o padrão de SubMundo já definido em ARQUITETURA_SUBMUNDOS_V1.md (Mundo → SubMundo → Bloco → Desafio).

---

## 1. Estrutura geral

**Mundo dos Esportes** passa a conter **9 SubMundos**, um por categoria esportiva:

1. Copa do Mundo
2. Futebol (masculino e feminino)
3. Basquete
4. Vôlei
5. Tênis
6. Fórmula 1
7. Natação
8. MMA/Lutas
9. Olimpíadas

**Nota de escopo**: "Futebol (masculino e feminino)" é tratado como **um único SubMundo**, cobrindo ambos, já que foi apresentado dessa forma. Se, durante a curadoria, ficar claro que o volume de conteúdo de cada vertente justifica separação em dois SubMundos distintos, isso deve ser sinalizado a Rhoney antes de decidir, não decidido unilateralmente.

## 2. Estrutura interna de cada SubMundo

Diferente do padrão usado no SubMundo da Internet (4 níveis de dificuldade × 20 perguntas), o Mundo dos Esportes segue um padrão mais enxuto, **sem níveis de dificuldade**:

- **4 Blocos** por SubMundo
- **5 Desafios** por Bloco
- **5 perguntas** por Desafio, direto (sem Fácil/Média/Difícil/Muito Difícil)

### 2.1 Cálculo de volume por SubMundo
4 Blocos × 5 Desafios × 5 perguntas = **100 perguntas por SubMundo**

### 2.2 Cálculo de volume total do Mundo dos Esportes
9 SubMundos × 100 perguntas = **900 perguntas ao todo**

## 3. Formato de cada pergunta

Mesmo padrão já validado nos Mundos anteriores: múltipla escolha com 4 alternativas, uma correta, texto original (nunca copiado de fonte), com fatos verificados via pesquisa antes da redação.

## 4. Regra de conteúdo — sensibilidade e neutralidade

- Times, atletas e federações reais devem ser tratados apenas com fatos verificáveis (recordes, datas, resultados históricos), nunca opinião sobre qual é "melhor" ou "pior" — mesmo princípio já usado com empresas reais no SubMundo da Internet.
- Rivalidades esportivas reais (ex.: clássicos de futebol) podem ser mencionadas como fato cultural/histórico, mas sem tomar partido.
- Atletas ainda vivos: fatos de carreira, recordes e biografia pública são permitidos; nada sobre vida pessoal não relacionada ao esporte.

## 5. Proposta de divisão temática dos 4 Blocos por SubMundo (sugestão inicial, ajustável)

Como orientação geral de curadoria (não uma regra rígida, já que cada esporte pode ter uma lógica própria de divisão):
- **Bloco 1**: Origens e história do esporte/competição
- **Bloco 2**: Grandes nomes e recordes
- **Bloco 3**: Regras, curiosidades técnicas e eventos marcantes
- **Bloco 4**: Presente, formatos atuais e curiosidades gerais

Cada SubMundo pode adaptar essa divisão à sua própria realidade (ex.: Copa do Mundo provavelmente organiza os Blocos por era/década ou por edições históricas marcantes, em vez desse esquema genérico).

## 6. Escopo técnico (a propor em detalhe por Claude Code)

- Confirmar que a estrutura de dados já criada para SubMundos (a partir da migração do SubMundo da Internet) suporta múltiplos SubMundos dentro de um único Mundo pai — o Mundo dos Esportes é o segundo caso de uso real dessa arquitetura, e vale confirmar que ela generaliza bem antes de escalar para 9 SubMundos de uma vez.
- Modelar os 9 SubMundos, cada um com 4 Blocos e 5 Desafios internos, seguindo a contagem de perguntas definida na seção 2.

## 7. Critério de aceite

- Mundo dos Esportes exibe corretamente os 9 SubMundos na navegação.
- Cada SubMundo contém exatamente 4 Blocos, cada Bloco com 5 Desafios, cada Desafio com 5 perguntas — sem níveis de dificuldade.
- Nenhuma pergunta expressa opinião sobre qual atleta/time/país é "melhor", mantendo neutralidade factual.
