# MENTAL — Convite de Amigos por Nome (substitui/complementa código)

**Status:** Aprovado para implementação, com ajuste de escopo em relação ao pedido original (ver seção 2).
**Contexto:** Nome do usuário passou a ser obrigatório e público (USER_PROFILE.md). Este documento formaliza a busca de amigos por nome, com autocomplete, complementando o convite por código já existente.
**Documento relacionado:** PERFIL_PUBLICO_E_TORCIDA_V1.md (define a regra de acesso a perfil "só a partir de ponto de contato prévio" — ver conflito na seção 2).

---

## 1. Especificação funcional

- Campo de busca na tela Amigos, com autocomplete disparado a partir da 3ª letra digitada.
- Sugestões exibem nome + foto + nível (mesmos dados já públicos, USER_PROFILE.md) — nunca e-mail ou outro dado sensível.
- Usuário seleciona da lista de sugestões e envia convite de amizade a partir dali.
- Convite por código é MANTIDO, não removido — ver seção 3.

## 2. Ressalva importante: conflito com regra já estabelecida

O PERFIL_PUBLICO_E_TORCIDA_V1.md definiu deliberadamente que a visita a perfil (e por extensão, a descoberta de outro usuário) só deveria acontecer **a partir de um ponto de contato prévio** (Ranking, Amigos já existentes, Batalha) — nunca busca livre por nome, exatamente para reduzir a superfície de uso indevido (ex.: alguém vasculhando o app atrás de pessoas específicas sem relação nenhuma).

Busca por nome com autocomplete quebra essa regra: permite que **qualquer usuário encontre qualquer outro**, mesmo sem nunca terem cruzado caminho no app.

**Decisão registrada para esta implementação:** a exceção é aceita aqui — mas escopada estritamente à intenção original (convidar alguém para amizade), não generalizada. Isso significa:
- A busca por nome só deve ficar disponível dentro do fluxo de **convite de amizade**, não como uma "busca geral de usuários" acessível de qualquer lugar do app.
- O resultado da busca leva direto à ação de "enviar convite" — não deve abrir automaticamente o perfil público completo da pessoa buscada (isso preservaria a regra original: perfil completo continua exigindo ponto de contato prévio, aqui só o nome+foto+nível aparecem, o mínimo necessário para identificar a pessoa certa).

## 3. Convite por código — mantido, não substituído

Motivo: código funciona **fora do app** (compartilhável por WhatsApp, link, etc.), o que busca por nome não faz. Os dois fluxos coexistem — nome para quem já está no app e quer achar alguém specific, código para convidar quem ainda pode nem ter o app instalado.

## 4. Tratamento de nomes duplicados

Como nome é público mas não único, o autocomplete deve exibir diferenciadores junto ao nome:
- Foto de perfil + nível (dados já públicos) ao lado de cada sugestão, para o usuário escolher a pessoa certa entre homônimos.

## 5. Especificação técnica

- Busca por prefixo no backend, indexada adequadamente (não full-text search pesado — é comparação de prefixo simples, ex. `LIKE 'nome%'` com índice, ou estrutura equivalente).
- Cliente (Flutter) deve aplicar debounce de ~300ms após a última tecla digitada antes de disparar a requisição, evitando uma chamada de API a cada letra.
- Resultado limitado a um número razoável de sugestões (ex.: top 8-10), não a lista completa de correspondências.
- Autoridade da busca permanece 100% no backend — cliente nunca faz filtro local de uma lista completa de usuários baixada previamente (isso seria uma exposição de dado muito maior que o necessário).

## 6. Análise de conformidade com políticas do Google Play

**Não há violação direta identificada.** Pontos verificados:

- **Não é uma feature de acesso a contatos do dispositivo** — a política mais restritiva do Google (Contacts Permissions, que exige uso do Android Contact Picker) rege acesso à agenda do telefone, não busca dentro do banco de usuários do próprio app. Este recurso não aciona essa política.
- **User Data Policy (transparência)**: exige que qualquer dado exibido seja "razoavelmente esperado pelo usuário" e que a declaração na Data Safety Section do Play Console bata com o comportamento real do app. Como nome, foto e nível já são dados públicos declarados (USER_PROFILE.md, já refletido na Política de Privacidade atual), exibir esses mesmos dados num autocomplete de busca não introduz categoria de dado nova — não deveria exigir nova declaração na Data Safety Section, mas vale confirmação humana no Play Console após implementar, seguindo o mesmo cuidado já aplicado no CHECKLIST_GOOGLE_PLAY_COMPLIANCE.md.
- **Nenhuma venda ou compartilhamento de dado com terceiro** está envolvida nesta feature — segue dentro do já declarado.

**Recomendação:** revalidar a Data Safety Section após a implementação, como item de rotina (mesmo padrão do checklist já usado), não porque se espera inconformidade, mas por disciplina — qualquer mudança de superfície de exposição de dado merece essa checagem de confirmação.

## 7. Critério de aceite

- Autocomplete funcional a partir da 3ª letra, com debounce e resultados limitados.
- Diferenciação clara entre usuários de mesmo nome (foto + nível).
- Busca por nome não abre perfil público completo diretamente — só leva à ação de convite.
- Convite por código continua funcionando, sem remoção.
- Nenhum dado além de nome, foto e nível (já públicos) exposto na busca.
