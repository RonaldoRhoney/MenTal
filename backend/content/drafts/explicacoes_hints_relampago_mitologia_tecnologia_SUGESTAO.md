# Sugestões de explanation + hints — rascunho (revisar com Claude antes de colar nos JSONs)

Dois arquivos ainda bloqueados na validação por faltar `explanation` (frase curta) e `hints`
(2 dicas progressivas, a 2ª mais reveladora) em cada item — conteúdo já com prompt/opções prontas.

---

## backend/content/mitologia_enem_concursos_relampago.json (14 itens)

### 1 — mitologia_grega (Zeus)
- explanation: "Zeus é o deus supremo da mitologia grega, senhor dos céus e dos raios, e governa o Monte Olimpo."
- hints: ["Sou o líder dos deuses do Olimpo.", "Meu símbolo é o raio."]

### 2 — mitologia_grega (calcanhar de Aquiles)
- explanation: "O calcanhar de Aquiles virou expressão popular para designar o único ponto fraco de alguém, mesmo quando parece invencível."
- hints: ["Minha mãe tentou me tornar invulnerável mergulhando-me num rio mágico.", "Ela me segurou por essa parte do corpo — que ficou de fora da água."]

### 3 — mitologia_nordica (Thor)
- explanation: "Thor é o deus nórdico do trovão, famoso por empunhar o martelo Mjölnir."
- hints: ["Sou filho de Odin.", "Meu martelo se chama Mjölnir."]

### 4 — mitologia_nordica (Odin)
- explanation: "Odin é o deus supremo nórdico, associado à sabedoria — sacrificou um olho em troca de conhecimento."
- hints: ["Sou considerado o pai de todos os deuses nórdicos.", "Tenho só um olho — troquei o outro por sabedoria."]

### 5 — mitologia_indigena (Saci-Pererê)
- explanation: "O Saci-Pererê é um dos personagens mais populares do folclore brasileiro: perna só, cachimbo e gorro vermelho."
- hints: ["Tenho uma perna só e um cachimbo na boca.", "Uso um gorro vermelho que me dá poderes mágicos."]

### 6 — mitologia_indigena (Curupira)
- explanation: "O Curupira protege as florestas na cultura popular brasileira — seus pés virados para trás confundem quem tenta segui-lo."
- hints: ["Protejo as florestas de caçadores e madeireiros.", "Meus pés são virados para trás, pra confundir meus rastros."]

### 7 — enem_matematica (desconto de 15%)
- explanation: "15% de R$ 200 é R$ 30; R$ 200 − R$ 30 = R$ 170."
- hints: ["Calcule primeiro quanto é 15% de R$ 200.", "Subtraia esse valor do preço original de R$ 200."]

### 8 — enem_humanas (vinda da família real)
- explanation: "Em 1808, a família real portuguesa se mudou para o Brasil fugindo de Napoleão, elevando o status da colônia."
- hints: ["Aconteceu em 1808, fugindo de uma invasão na Europa.", "A família real portuguesa cruzou o Atlântico e se instalou no Rio de Janeiro."]

### 9 — enem_natureza (fotossíntese)
- explanation: "Fotossíntese é o processo pelo qual plantas transformam luz solar em energia química, liberando oxigênio."
- hints: ["Só acontece na presença de luz.", "Libera oxigênio como subproduto."]

### 10 — enem_linguagens (personificação)
- explanation: "Personificação (ou prosopopeia) atribui características humanas a seres inanimados ou animais."
- hints: ["É uma figura de linguagem, não um erro gramatical.", "Exemplo: 'o vento sussurrava' — o vento não fala de verdade."]

### 11 — concursos_portugues (porém = oposição)
- explanation: "'Porém' é uma conjunção adversativa — introduz uma ideia que contrasta com a anterior."
- hints: ["A frase tem duas ideias que se contradizem.", "'Porém' tem o mesmo sentido de 'mas'."]

### 12 — concursos_raciocinio (silogismo)
- explanation: "Se todo A é B e todo B é C, por transitividade todo A é C — silogismo clássico da lógica."
- hints: ["Pense em conjuntos: A está dentro de B, e B está dentro de C.", "Se A está dentro de B, e B está dentro de C, A também está dentro de C."]

### 13 — concursos_direito (Constituição Cidadã)
- explanation: "A Constituição de 1988 é chamada de 'Constituição Cidadã' por ampliar direitos sociais após a redemocratização."
- hints: ["Foi promulgada em 1988, após o fim da ditadura militar.", "O apelido remete à ampliação de direitos dos cidadãos."]

### 14 — concursos_direito (ODS)
- explanation: "Os Objetivos de Desenvolvimento Sustentável (ODS) são 17 metas da ONU, definidas em 2015, para até 2030."
- hints: ["Foram definidas pela ONU em 2015.", "São 17 metas, incluindo erradicar a pobreza e agir contra as mudanças climáticas."]

---

## backend/content/tecnologia_relampago.json (9 itens)

### 1 — tecnologia_fundamentos (servidor)
- explanation: "Um servidor é um computador (ou conjunto deles) que fica sempre ligado, recebendo e enviando dados entre usuários."
- hints: ["Fico ligado o tempo todo, em um data center.", "Recebo sua mensagem e a repasso pro destinatário."]

### 2 — tecnologia_fundamentos (software)
- explanation: "Software é a parte não-física do computador — o código e os programas, em oposição ao hardware (peças físicas)."
- hints: ["Você não pode me tocar fisicamente.", "Sou o conjunto de programas e código que roda na máquina."]

### 3 — tecnologia_fundamentos (endereço IP)
- explanation: "O endereço IP é o número que identifica um computador na internet — o DNS traduz nomes de sites para esse número."
- hints: ["Sou uma sequência de números, não de letras.", "Cada dispositivo conectado à internet tem um dos meus, para ser encontrado."]

### 4 — tecnologia_programacao (variável)
- explanation: "Variável é um espaço nomeado que guarda um valor que pode mudar durante a execução do programa."
- hints: ["Tenho um nome, mas meu conteúdo pode mudar.", "Guardo valores como texto, número ou verdadeiro/falso."]

### 5 — tecnologia_programacao (estrutura condicional)
- explanation: "Estrutura condicional (if/else) permite ao programa escolher um caminho diferente dependendo de uma condição."
- hints: ["Tenho a ver com 'se isso, então aquilo'.", "Em código, normalmente apareço como 'if' e 'else'."]

### 6 — tecnologia_programacao (algoritmo)
- explanation: "Algoritmo é uma sequência ordenada de passos para resolver um problema — como uma receita para o computador seguir."
- hints: ["Sou uma sequência de passos, não uma linguagem específica.", "Uma receita de bolo é um exemplo do meu conceito, fora da computação."]

### 7 — tecnologia_seguranca (phishing)
- explanation: "Phishing é um golpe que finge ser uma instituição confiável (banco, empresa) para roubar dados da vítima."
- hints: ["Costumo imitar mensagens de bancos ou empresas conhecidas.", "Meu objetivo é fazer você clicar num link e entregar sua senha."]

### 8 — tecnologia_seguranca (autenticação em duas etapas)
- explanation: "Autenticação em duas etapas exige um segundo código (SMS, app) além da senha, dificultando o acesso de invasores."
- hints: ["Uso a senha e mais um segundo fator.", "Costumo chegar por SMS ou um aplicativo autenticador."]

### 9 — tecnologia_fronteira (Inteligência Artificial)
- explanation: "Inteligência Artificial é o campo que cria sistemas que aprendem padrões a partir de dados, em vez de seguir regras fixas escritas por humanos."
- hints: ["Aprendo com exemplos, em vez de seguir regras fixas.", "Melhoro meu desempenho com mais dados e tempo de treino."]
