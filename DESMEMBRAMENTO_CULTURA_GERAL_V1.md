# MENTAL — Desmembramento do Mundo da Cultura Geral

**Status:** Implementado (07/09/2026) — ver seção 9. Pendência residual: curadoria dos 5 territórios de região (§3).
**Origem:** Mundo da Cultura Geral hoje reúne territórios de naturezas muito diferentes num único balaio genérico. Esta especificação desmembra esse Mundo em Mundos temáticos dedicados, e move dois territórios para Mundos já existentes que combinam melhor com eles.

---

## 1. Objetivo

Reorganizar o conteúdo hoje agrupado sob "Mundo da Cultura Geral", criando Mundos próprios e coesos para cada grande tema, e realocando os dois territórios que já têm um lar mais natural em Mundos já existentes (Idiomas e Valores).

## 2. Mapeamento completo: de onde vem, para onde vai

### 2.1 Territórios que viram Mundo próprio (novo)
| Território hoje em Cultura Geral | Novo Mundo |
|---|---|
| Esportes | **Mundo dos Esportes** |
| Mitologia (grega, nórdica, indígena) | **Mundo da Mitologia** |
| ENEM (matemática, ciências humanas, ciências da natureza, linguagens) | **Mundo do ENEM** |
| Concursos (português, raciocínio lógico, direito) | **Mundo dos Concursos** |
| Tecnologia (fundamentos, programação, segurança, fronteira) | **Mundo da Tecnologia** |
| Regiões do Brasil | **Mundo das Regiões do Brasil** (ver detalhamento na seção 3) |

### 2.2 Territórios que migram para Mundo já existente
| Território hoje em Cultura Geral | Mundo de destino |
|---|---|
| Libras | **Mundo dos Idiomas** (V5, já existente) |
| Finanças Pessoais | **Mundo dos Valores** (V6, já existente) |

### 2.3 O que permanece em Mundo da Cultura Geral
Qualquer território não listado acima permanece como está — este documento não desmembra o Mundo por completo, apenas os itens explicitamente listados nas tabelas 2.1 e 2.2. Se, ao investigar o código, Claude Code encontrar outros territórios hoje agrupados em Cultura Geral não mencionados aqui, deve reportar e aguardar decisão antes de movê-los.

## 3. Detalhamento: Mundo das Regiões do Brasil

Diferente dos demais, este novo Mundo não é só uma renomeação simples — as **cinco regiões do Brasil (Norte, Nordeste, Centro-Oeste, Sudeste, Sul) passam a ser o contexto organizador** de todos os desafios e Relâmpagos dentro desse Mundo, cada região funcionando como um território próprio dentro do Mundo, reunindo curiosidades, geografia, cultura e características específicas de cada uma.

## 4. O que NÃO muda

- Nenhum item de conteúdo (pergunta, cápsula, desafio) é alterado, reescrito ou removido — esta é uma reorganização de estrutura/categoria, não uma mudança de conteúdo.
- Progresso, XP, estatísticas e histórico de usuários em qualquer território movido devem ser preservados integralmente, mesmo que agora estejam sob um Mundo diferente.
- Mundo dos Idiomas e Mundo dos Valores mantêm toda sua estrutura já existente — Libras e Finanças Pessoais apenas se somam ao que já está lá.

## 5. Investigação necessária antes de implementar

Antes de mover qualquer coisa, Claude Code deve confirmar e reportar:
- Como a estrutura atual vincula território a Mundo no código/banco (nome do campo, tabela) — mesmo levantamento já feito em reorganizações anteriores de Mundo.
- Se existe algum território dentro de "Regiões do Brasil" hoje, ou se esse conteúdo precisa ser criado do zero como parte desta reorganização (a criação de conteúdo novo, se necessária, é trabalho de curadoria separado, a ser tratado depois da reorganização estrutural).
- Se há qualquer outro lugar do app (Admin Dashboard, notificações, deep links, Ranking) que referencia "Mundo da Cultura Geral" pelo nome e precisaria de ajuste também.

## 6. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Criar os 6 novos Mundos (Esportes, Mitologia, ENEM, Concursos, Tecnologia, Regiões do Brasil) na estrutura de Mundos já existente do app, mesmo padrão usado nas reorganizações anteriores (ex.: criação do Mundo da Descoberta).
- Mover o vínculo dos territórios listados na seção 2.1 para seus respectivos novos Mundos.
- Mover o vínculo de Libras para Mundo dos Idiomas, e de Finanças Pessoais para Mundo dos Valores.
- Atualizar toda referência de UI/navegação (Home, menus, Admin Dashboard) para refletir a nova estrutura.
- Se "Regiões do Brasil" ainda não existir como território com conteúdo real, sinalizar isso como pendência de curadoria, sem bloquear a criação da estrutura vazia do Mundo em si.

## 7. Critério de aceite

- Os 6 novos Mundos existem e aparecem corretamente na Home, cada um com seu território correspondente.
- Libras aparece dentro do Mundo dos Idiomas; Finanças Pessoais aparece dentro do Mundo dos Valores.
- Mundo da Cultura Geral permanece existindo, contendo apenas o que não foi explicitamente movido por este documento.
- Nenhum progresso, XP ou estatística de usuário é perdido em nenhum dos territórios movidos.
- Mundo das Regiões do Brasil está estruturalmente pronto para receber as cinco regiões como territórios internos, mesmo que a curadoria de conteúdo completa de cada região seja tratada em etapa posterior.

## 8. Investigação (seção 5) — resultado

- **Vínculo território↔Mundo**: campo `world_id` em cada entrada de `TERRITORIES` (`backend/app/seed.py`), espelhado em `mental.territories.world_id` no banco (migrations). "Bloco" (`block_id`) é agrupamento visual de menu independente do Mundo — não precisou ser tocado nesta reorganização.
- **"Regiões do Brasil" já existia?** Não como pensado no documento. O território `regioes` (15 perguntas) é sobre **gírias e expressões regionais** (cada pergunta mistura várias regiões), não conteúdo dividido por região. Decisão de Rhoney (AskUserQuestion, 07/09/2026): manter essas 15 perguntas como território próprio, renomeado "Gírias e Expressões", dentro do novo Mundo — os 5 territórios de região ficam como pendência de curadoria (ver `Mundo_das_Regioes_do_Brasil/README.md`).
- **Outras referências a "Cultura Geral" por nome**: nenhuma fora de `backend/app/seed.py` (definição) e `client/lib/screens/home_screen.dart` (ícone do carrossel, `case 'cultura_geral':`) — nada em Admin Dashboard, notificações ou deep links. Badges de "Mundo completo" são sempre derivados na hora (nunca armazenados), então a divisão não tem efeito colateral em progresso/conquista já registrada.

## 9. Implementação (07/09/2026)

- `backend/app/seed.py`: 6 novos Mundos adicionados a `WORLDS` (display_order 8-13); `world_id` atualizado nos territórios movidos (ver seção 2).
- `backend/migrations/067_desmembramento_cultura_geral.sql`: insere os 6 Mundos e faz o `UPDATE` de `world_id` em produção — precisa rodar manualmente (mesmo fluxo já usado nas migrations anteriores).
- `client/lib/screens/home_screen.dart`: ícone de identidade no carrossel pros 6 novos Mundos (`_worldIcon`).
- `client/lib/l10n/app_pt.arb`: rótulo do território `regioes` trocado de "Regiões" pra "Gírias e Expressões".
- READMEs criados: `Mundo_dos_Esportes/`, `Mundo_da_Mitologia/`, `Mundo_do_ENEM/`, `Mundo_dos_Concursos/`, `Mundo_da_Tecnologia/`, `Mundo_das_Regioes_do_Brasil/` (este último documenta a pendência de curadoria das 5 regiões). `Mundo_da_Cultura_Geral/`, `Mundo_dos_Idiomas/` e `Mundo_dos_Valores/` atualizados para refletir a nova composição.
- Testes: `backend/tests/test_worlds.py` (`test_progress_groups_territories_into_the_approved_worlds`) reescrito pra refletir os 13 Mundos. Suíte completa: 376/376 backend, 146/146 client — nenhum outro teste dependia da composição antiga de Cultura Geral.
