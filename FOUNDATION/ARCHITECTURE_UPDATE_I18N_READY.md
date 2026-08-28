# MENTAL — ATUALIZAÇÃO DE ARQUITETURA: PREPARADO PARA I18N (SEM LANÇAR MULTI-IDIOMA)

Status: aprovado por Rhoney (dono). Atualiza `ARCHITECTURE.md`.

## 1. Decisão

O MENTAL será lançado **100% em português**, com todo o conteúdo (Palavras,
Números, Lógica, Conhecimentos gerais) curado apenas nesse idioma. Mas a
arquitetura — client e backend — deve nascer **pronta para internacionalização**,
para que adicionar um novo idioma no futuro seja trabalho de conteúdo e
configuração, não retrabalho estrutural de código.

## 2. Por que esta distinção existe

Diferente de apps utilitários (onde traduzir é trocar texto de UI), o
conteúdo do MENTAL é o próprio produto:

- **Palavras**: depende do idioma em si (anagrama, ortografia) — não
  traduz, precisa ser recriado por idioma.
- **Conhecimentos gerais**: depende de contexto cultural/regional — precisa
  de banco curado próprio por idioma/região, não só tradução de pergunta.
- **Lógica e Números** traduzem razoavelmente bem (raciocínio é mais
  universal), mas ainda assim precisam de revisão por idioma.

Isso significa que "lançar em vários idiomas" no MENTAL é, na prática,
multiplicar o trabalho de curadoria de conteúdo por idioma — não um
multiplicador simples de tradução de strings. Dado o contexto de dev solo e
os riscos já identificados de volume mínimo de conteúdo (mesmo só em
português), a decisão é: **preparar a estrutura agora, popular conteúdo em
outros idiomas apenas quando houver demanda real** (ex.: instalações vindas
de outro país, pedido de usuário).

## 3. O que muda tecnicamente

**Client (Flutter):**
- Toda string de interface (botões, rótulos, mensagens de sistema, textos
  fixos de UI) deve usar o sistema de internacionalização nativo do
  Flutter (`intl` + arquivos `.arb`), desde o início — mesmo que hoje só
  exista `pt_BR.arb` populado.
- Nenhum texto de UI deve ser hardcoded diretamente no código Dart.
- Nenhuma tela deve assumir texto de tamanho fixo em português — strings
  em outros idiomas podem ser mais longas ou mais curtas; o layout deve
  suportar variação de tamanho de texto sem quebrar.

**Backend (FastAPI) e dados:**
- O schema de `challenges` (e tabelas relacionadas) deve incluir um campo
  de idioma/locale (ex.: `language_code`, formato `pt-BR`) desde já, mesmo
  que hoje 100% dos registros sejam `pt-BR`. Isso evita uma migração de
  schema dolorosa quando o segundo idioma for adicionado.
- Endpoints que retornam conteúdo de desafio devem já aceitar (ou ao menos
  prever) um parâmetro de idioma, mesmo que hoje só haja um valor possível
  e o comportamento padrão seja retornar `pt-BR` sempre.
- Textos de sistema gerados pelo backend (mensagens de erro, textos de
  notificação, se existirem) devem seguir o mesmo princípio: não hardcoded
  misturado à lógica, preparado para troca por idioma no futuro.

**O que NÃO fazer agora:**
- Não criar conteúdo de desafio em outros idiomas.
- Não implementar seletor de idioma na UI (a menos que seja trivial e não
  atrase nada — decisão do Claude Code, não é requisito).
- Não gastar tempo projetando pipeline de tradução automatizada ou
  ferramenta de gestão de conteúdo multilíngue — isso é over-engineering
  para o estágio atual do produto.

## 4. Critério de aceite

A arquitetura está "i18n-ready" quando: adicionar um segundo idioma no
futuro significa (a) popular um novo `.arb` no client, (b) inserir novos
registros de `challenges` com `language_code` diferente, e (c) nenhuma
alteração estrutural de código em nenhuma das duas camadas. Se qualquer uma
dessas três exigir refatoração de arquitetura quando chegar a hora, esta
tarefa não foi implementada corretamente agora.

## 5. Papel de cada parte

- **Rhoney**: decide quando e para qual idioma expandir, com base em
  demanda real observada após o lançamento.
- **Claude (arquitetura)**: garante que o critério de aceite da Seção 4 é
  respeitado antes de aprovar esta tarefa como concluída.
- **Claude Code**: implementa a estrutura i18n-ready no client e no
  backend, sem produzir conteúdo em outro idioma nem UI de seleção de
  idioma além do estritamente necessário para não travar nada depois.
