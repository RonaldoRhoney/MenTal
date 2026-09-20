# MENTAL — Mundo dos Idiomas: Biblioteca Visual (Foto/GIF) para Todos os Idiomas

**Status:** Estrutura de dado/interface IMPLEMENTADA (18/09/2026, junto com MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md — ver esse documento pros detalhes técnicos: `Challenge.vocab_media_url/type/source_name/source_url`). Curadoria de conteúdo (seção 5 abaixo) EM ANDAMENTO (19/09/2026): piloto de ilustração gerada via Canva ("dirigir/Drive") aprovado por Rhoney e já exibido na Constelação de Palavras; produção em lote por território iniciada (`backend/scripts/vocab_manifest.json`, `scripts/upload_vocab_media.py --manifest`), 4 de 45 imagens de `ingles_basico` prontas, pausada por limite da cota de geração do Canva. Fotos/GIFs/vídeos licenciados de terceiros continuam NÃO iniciados — o que existe até agora é ilustração original gerada, com atribuição "Ilustração gerada via Canva AI (MENTAL)".
**Escopo:** Generaliza a especificação original de Libras (vídeo/GIF do sinal) para uma estrutura extensível que cobre todos os idiomas do Mundo dos Idiomas (Inglês, Espanhol, Francês, Libras, e idiomas futuros).
**Documento relacionado:** MUNDO_IDIOMAS_AUDIO_PRONUNCIA_V1.md (já aprovado — TTS de pronúncia ao tocar na resposta, para idiomas falados). Este documento trata do **reforço visual** (imagem/GIF), complementar ao áudio, não uma substituição dele.

---

## 1. Objetivo

Adicionar reforço visual (foto ou GIF) a cada item de vocabulário do Mundo dos Idiomas, ajudando a fixar o significado da palavra através de associação visual direta — princípio pedagógico básico de aprendizado de idiomas (ver a imagem da "casa" ao aprender "house", não só ler a tradução).

Para Libras especificamente, o vídeo/GIF não é um reforço opcional — é o **próprio conteúdo central**, já que Libras é uma língua visual-gestual e o sinal em movimento é indissociável do vocabulário em si.

## 2. Estrutura extensível por tipo de idioma

### 2.1 Idiomas falados (Inglês, Espanhol, Francês, e futuros)
- Cada item de vocabulário recebe uma **foto ou GIF curto** ilustrando o significado da palavra (ex.: "house" → foto de uma casa).
- Esse reforço visual funciona **em conjunto** com o áudio de pronúncia já aprovado — o usuário vê a imagem, ouve a pronúncia ao tocar na resposta, e lê a palavra escrita, reforçando os três canais de aprendizado ao mesmo tempo.
- Nem toda palavra exige imagem (ex.: conectivos, preposições, palavras abstratas) — a curadoria deve avaliar item a item se a associação visual agrega valor real, e não forçar imagem onde não faz sentido pedagógico.

### 2.2 Libras (idioma visual-gestual)
- Cada item de vocabulário recebe um **vídeo curto ou GIF** demonstrando o sinal correspondente, gravado ou obtido de fonte licenciada de forma correta.
- Diferente dos idiomas falados, aqui o vídeo/GIF é obrigatório para praticamente todo item, já que não existe "pronúncia falada" alternativa para Libras — o sinal é o próprio conteúdo.

## 3. Curadoria de conteúdo visual — regras de direitos autorais

- Priorizar imagens/vídeos de bancos com licença aberta e verificável (ex.: Wikimedia Commons, mesmo padrão já usado com sucesso no território Ouvido Afiado do Mundo da Descoberta), verificando e documentando a licença individualmente por item (CC0, CC BY, CC BY-SA, domínio público), nunca assumindo licenciamento em lote.
- Para Libras especificamente, avaliar prioritariamente fontes especializadas em Libras com licença aberta, ou gravação própria/parceria com intérprete, dado o cuidado adicional já sinalizado em pendências anteriores do projeto (V3.4 Libras aguardando validação humana especializada antes de produção).
- Não usar imagens geradas por IA como substituto de fotografia real quando o objetivo pedagógico for mostrar um objeto/cena do mundo real (ex.: "casa", "carro") — preferir fotos reais nesses casos. Ilustração/GIF gerado é aceitável para conceitos mais abstratos, desde que a qualidade visual seja consistente com a identidade do app.

## 4. Onde aparece na interface

- O reforço visual aparece junto à pergunta de vocabulário (mesmo formato de cápsula já usado no Mundo dos Idiomas), antes ou ao lado do texto da pergunta — não deve substituir o texto, apenas complementá-lo.
- Para Libras, o vídeo/GIF do sinal é o elemento central da pergunta, já que a própria mecânica de "como se diz X em Libras" depende de mostrar visualmente as opções de resposta (o usuário reconhece o sinal correto entre alternativas, ou vê o sinal e escolhe o significado correto).

## 5. Escopo de implementação — abordagem em fases

Dado o volume de conteúdo já existente (90+ blocos de vocabulário no Mundo dos Idiomas, mais o que vier a ser adicionado), a curadoria visual completa de todo o conteúdo já publicado é um trabalho extenso. Recomenda-se abordagem em fases:

- **Fase 1 (piloto):** aplicar a biblioteca visual num recorte piloto — sugestão: um nível completo de um idioma (ex.: Inglês Básico) — para validar o fluxo de curadoria, licenciamento e integração técnica antes de escalar.
- **Fase 2:** expandir gradualmente para os demais níveis e idiomas já publicados, priorizando os territórios de maior uso real (a definir com base em dados do Admin Dashboard, se disponíveis).
- **Fase 3:** todo conteúdo novo criado a partir de agora já nasce com a etapa de curadoria visual incluída no processo, em vez de ser tratado como pendência futura.

## 6. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Adicionar campo(s) de mídia visual (URL de imagem/GIF/vídeo + metadado de licença/fonte) à estrutura de dado já existente de cada item de vocabulário, de forma extensível para comportar tanto foto estática quanto GIF/vídeo curto.
- Estrutura de dado deve ser agnóstica de idioma — o mesmo schema serve tanto para o reforço visual de idiomas falados quanto para o vídeo/GIF de Libras, apenas variando o tipo de mídia predominante esperado.
- Avaliar estratégia de armazenamento (Supabase Storage, já usado para foto de perfil, ou CDN externo) considerando volume e tamanho de arquivo, especialmente para GIFs/vídeos de Libras.
- Garantir que a ausência de mídia visual num item (enquanto a curadoria da Fase 2/3 não chegar até ele) não quebre a exibição da pergunta — o app deve funcionar normalmente com ou sem o reforço visual presente.

## 7. Critério de aceite

- Estrutura de dado extensível implementada, suportando imagem/GIF para idiomas falados e vídeo/GIF para Libras, com metadado de licença por item.
- Piloto da Fase 1 (um nível completo de um idioma) com curadoria visual completa, licenciamento verificado item a item, e integração funcionando na interface.
- Ausência de mídia visual em itens ainda não curados não quebra a experiência do usuário.
- Nenhuma imagem usada sem verificação individual de licença, seguindo o mesmo padrão já validado no território Ouvido Afiado.
