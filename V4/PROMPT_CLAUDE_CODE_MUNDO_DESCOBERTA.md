Preciso que você crie um novo Mundo chamado "Mundo da Descoberta" e mova para ele todos os 5 territórios da V4, que hoje estão dentro de "Mundo Cultura Geral" — esse Mundo ficou extenso e cansativo demais para o usuário navegar, e isso resolve organizando os territórios recém-adicionados em um Mundo próprio.

## O que fazer

1. Criar o novo Mundo "Mundo da Descoberta" na estrutura de Mundos já existente do app (mesmo padrão de Mundo da Linguagem, Mundo da Mente Lógica, etc.).

2. Mover para dentro dele os 5 territórios da V4, que hoje estão em "Mundo Cultura Geral":
   - Invenções, Grandes Construções e Como Surge uma Ideia
   - Carros, Motos e Aviões
   - Astronomia e Espaço
   - Detetive Mental
   - Ouvido Afiado

3. Verificar se "Mundo Cultura Geral" tem outros territórios além desses 5 (ex.: Esportes, Regiões, Cultura Pop, da V3.0, que também podem estar lá). Se tiver, eles permanecem em "Mundo Cultura Geral" — apenas os 5 territórios da V4 saem de lá. Não mover nada além do que está listado acima sem antes reportar e confirmar comigo.

4. Atualizar toda referência de UI/navegação (Home, menus, qualquer lugar que hoje mostre esses territórios como parte de "Mundo Cultura Geral") para refletir o novo Mundo.

5. Preservar todo o progresso, XP, estatísticas e histórico dos usuários nesses territórios — esta é uma reorganização de estrutura/categoria visual, não uma migração de dado de jogo. Nenhum progresso pode ser perdido ou resetado.

6. Se a estrutura de dado do app vincular território a Mundo via alguma FK/campo de categoria, migrar esse vínculo corretamente — não deixar territórios "órfãos" nem duplicados em dois Mundos ao mesmo tempo.

## Investigação antes de alterar

Antes de mexer em qualquer coisa, confirme e me reporte:
- Como a estrutura atual vincula território a Mundo no código/banco (nome do campo, tabela).
- Se "Mundo Cultura Geral" tem outros territórios além dos 5 da V4 que devem permanecer lá.
- Se existe algum outro lugar do app (ex.: Admin Dashboard, notificações, deep links) que referencia "Mundo Cultura Geral" pelo nome e precisaria de ajuste também.

## Critério de aceite

- "Mundo da Descoberta" existe e aparece corretamente na Home, com os 5 territórios da V4 dentro dele.
- "Mundo Cultura Geral" permanece com qualquer outro território que não seja da V4 (se houver).
- Nenhum progresso, XP ou estatística de usuário é perdido nessa reorganização.
- Testes automatizados relacionados a listagem de Mundos/territórios continuam passando, com ajustes onde necessário para refletir a nova estrutura.
- Nenhuma referência quebrada ao nome antigo em qualquer parte do app.
