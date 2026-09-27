
## Roadmap decidido por Rhoney (26/09/2026)
1. **Agora (custo zero):** vocabulário curado com todas as opções (vários significados e idiomas); tradução de frases no aparelho (Google ML Kit, gratuito e offline); busca no conteúdo curado para dúvidas de gramática. Sem IA generativa.
2. **Depois, com vocabulário robusto:** aplicação em frases — frase-exemplo curada e revisada por palavra (nunca gerada por modelo). Só começa quando Básico, Intermediário e Avançado estiverem completos.

## Entendimento de perguntas e aprendizado com o uso (26/09/2026)
- **Limpeza da pergunta:** "?", "." ou sem pontuação; preâmbulos ("oi", "então você pode me dizer...") e fechos ("por favor") são ignorados.
- **Pedidos de frase-exemplo por intenção:** se a pergunta pede frase/exemplo/uso, as palavras de comando das pontas são tiradas e o que sobra é o termo ("crie uma frase em inglês com a palavra queijo" → queijo). Vale para qualquer forma parecida, sem lista fixa de frases.
- **Expansível sem deploy:** modos de perguntar APROVADOS ficam na tabela `mental.lingo_padroes` (regex; grupo 1 = termo; grupo 2 opcional = idioma; intenção `traducao` ou `exemplo`). Cadastro: `python3 scripts/lingo_aprendizado.py padrao <intencao> "<regex>" "pergunta de teste"` (valida a regex e testa antes de gravar).
- **Aprende com o uso, sem IA e sem usuário:** o que o Lingo NÃO entendeu é registrado só como agregado (texto normalizado + contador, sem e-mail/números longos) em `mental.lingo_perguntas_nao_entendidas`. Ver a fila: `python3 scripts/lingo_aprendizado.py perguntas`. Nada é aprendido sozinho: um padrão só entra depois de aprovado por Rhoney.
- **Privacidade:** a tabela de perguntas não tem coluna de usuário; incluir "perguntas não entendidas (agregado, anônimo)" na política de privacidade/Data Safety antes de subir versão.
