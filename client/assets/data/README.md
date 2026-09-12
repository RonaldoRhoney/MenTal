# Dados estáticos embutidos no app

## brazil_cities.json

- **Fornecedor**: IBGE (Instituto Brasileiro de Geografia e Estatística) — dado aberto governamental.
- **URL oficial**: `https://servicodados.ibge.gov.br/api/v1/localidades/municipios`
- **Finalidade**: autocomplete de Cidade por Estado no cadastro (onboarding obrigatório e tela de Perfil) — Estado virou lista fixa de UFs em 12/09/2026 (`client/lib/brazil_states.dart`); Cidade continua texto livre, mas com sugestões filtradas pela UF escolhida.
- **Licença**: dado público governamental, sem restrição de uso — mesma categoria de "dados.gov.br" no topo da ordem de preferência da skill zero-cost-api.
- **Autenticação**: nenhuma.
- **Custo/risco de cobrança**: nenhum — `cost_status: ZERO_COST`.
- **Estratégia**: baixado UMA VEZ (12/09/2026, 5.571 municípios confirmados nas 27 UFs) e empacotado como asset estático — nunca consultado em runtime. Elimina dependência de rede/disponibilidade do IBGE para uma funcionalidade de cadastro, e mantém o app funcionando 100% offline pra essa etapa.
- **Formato**: `{"UF": ["Cidade A", "Cidade B", ...], ...}`, cidades em ordem alfabética dentro de cada UF.
- **Atualização futura**: municípios brasileiros raramente mudam (a última criação foi Balneário Rincão-SC em 2013) — não há necessidade de reprocessar periodicamente. Se necessário, repetir a mesma chamada e regenerar o arquivo.
