# Política de Privacidade — MENTAL

**Última atualização:** 22 de agosto de 2026

Esta Política de Privacidade descreve como o aplicativo **MENTAL**, desenvolvido por **RhoneyInc**, coleta, usa e protege as informações dos usuários.

O MENTAL é um aplicativo de desafios cognitivos gamificados, destinado a um público misto (crianças, adolescentes, adultos e idosos). Por isso, esta política segue com rigor as exigências da **Política para Famílias do Google Play** e da **Lei Geral de Proteção de Dados (LGPD)**.

---

## 1. Quem somos

O MENTAL é desenvolvido e mantido por **RhoneyInc**, estúdio de produtos digitais sediado em Belém, Pará, Brasil.

**Contato para questões de privacidade:** rhoneyinc@gmail.com

---

## 2. Quais dados coletamos

### 2.1 Dados obrigatórios (necessários para o funcionamento do app)
- **E-mail** — usado para criação de conta, login e recuperação de acesso (via Supabase Auth).
- **Nickname (apelido)** — usado para identificação do jogador dentro do app (ranking, amigos, badges).
- **Confirmação de faixa etária** — coletada através de uma tela neutra de verificação de idade, exigida antes de qualquer outra coleta de dado. Usada exclusivamente para ativar o modo de proteção infantil (`child_safe_mode`) quando aplicável.

### 2.2 Dados opcionais (o usuário escolhe se preenche)
- **Avatar** — escolhido entre ilustrações pré-definidas oferecidas pelo app. O MENTAL **não permite upload de fotos reais** como avatar.
- **Nome real** — campo opcional, usado apenas para fins internos (ex.: contato/suporte). **Nunca é exibido publicamente** em nenhuma tela do app (ranking, amigos, badges).
- **Estado/país** — campo opcional e de granularidade intencionalmente ampla. O MENTAL **não coleta cidade exata nem localização geográfica precisa (GPS)**. A exibição pública desse dado depende de escolha explícita do usuário.

### 2.3 Dados de progresso e uso do jogo
- Pontuação (XP), nível, territórios conquistados, badges/conquistas, estatísticas de desempenho (acertos, erros, sequência de dias jogados).
- Contagem de passos (via sensor de hardware do dispositivo, `TYPE_STEP_COUNTER`) — coletada apenas se o usuário conceder a permissão correspondente, usada exclusivamente para a funcionalidade de gamificação por movimento dentro do app. **Não coletamos dados de localização GPS associados aos passos.**
- Preferências de notificação (quais tipos de notificação o usuário optou por receber).

### 2.4 Dados de autenticação social (opcional)
- Se o usuário optar por entrar com **Google**, recebemos apenas as informações básicas de identificação fornecidas pelo provedor (e-mail e identificador de conta), conforme autorizado pelo usuário no momento do login.

---

## 3. O que NÃO coletamos

- **Não coletamos Identificador de Publicidade (AAID)** de usuários com idade não confirmada ou confirmada como criança.
- **Não coletamos número de telefone.**
- **Não coletamos localização GPS/geolocalização precisa.**
- **Não solicitamos upload de fotos reais** de perfil.
- **Não exibimos publicidade personalizada** para usuários com idade não confirmada ou confirmada como criança — atualmente, o MENTAL **não exibe nenhum tipo de publicidade** (aplicativo 100% gratuito).

---

## 4. Como usamos os dados coletados

Os dados são usados exclusivamente para:
- Autenticar o usuário e manter sua conta segura.
- Exibir seu progresso, conquistas e desempenho dentro do app.
- Personalizar a dificuldade dos desafios de acordo com o desempenho individual.
- Enviar notificações que o usuário optou por receber (reengajamento, atividade social entre amigos).
- Viabilizar funcionalidades sociais entre amigos (ranking entre amigos, desafios assíncronos) — sempre restritas a conexões que o próprio usuário estabeleceu.

**Não vendemos, alugamos ou compartilhamos dados pessoais com terceiros para fins de publicidade.**

---

## 5. Proteção especial para crianças

O MENTAL segue o princípio de que, até que a idade do usuário seja confirmada, ele é tratado como se fosse uma criança:

- Nenhum identificador de publicidade é transmitido antes da confirmação de idade adulta.
- Nenhum SDK de terceiros (analytics, publicidade) é inicializado fora do modo de proteção infantil por padrão.
- Perfis em modo de proteção infantil (`child_safe_mode`) têm identidade sempre anonimizada em qualquer contexto social (ranking, disputas, notificações) — nome real nunca é exibido, e comparações com outros jogadores nunca identificam o outro usuário nominalmente.
- Não existe conteúdo gerado por usuários (UGC) nem upload de imagens por usuários no MENTAL atualmente.

---

## 6. Compartilhamento de dados

Utilizamos os seguintes serviços de terceiros para operar o aplicativo, cada um recebendo apenas o dado estritamente necessário para sua função técnica:

- **Supabase** — armazenamento de dados de conta e progresso do jogo, autenticação.
- **Google Firebase Cloud Messaging (FCM)** — exclusivamente para entrega de notificações push; não é utilizado como banco de dados nem para fins de publicidade.
- **Google Sign-In** — autenticação opcional via conta Google, apenas quando o usuário escolhe esse método de login.

Nenhum desses serviços recebe dados além do estritamente necessário para sua função, e nenhum é utilizado para publicidade direcionada.

---

## 7. Retenção e exclusão de dados

- Os dados do usuário são mantidos enquanto a conta estiver ativa.
- O usuário pode solicitar a exclusão completa de sua conta e de todos os dados associados a qualquer momento, entrando em contato através do e-mail informado na seção 1.
- Após solicitação de exclusão, os dados são removidos permanentemente de nossos sistemas em prazo razoável, conforme exigido pela LGPD.

---

## 8. Direitos do usuário (LGPD)

Conforme a Lei Geral de Proteção de Dados (Lei nº 13.709/2018), o usuário tem direito a:
- Confirmar a existência de tratamento de seus dados.
- Acessar os dados que temos sobre ele.
- Corrigir dados incompletos, inexatos ou desatualizados.
- Solicitar a exclusão de dados pessoais.
- Revogar o consentimento a qualquer momento.

Para exercer qualquer um desses direitos, entre em contato através do e-mail informado na seção 1.

---

## 9. Segurança

Empregamos práticas de segurança técnica para proteger os dados dos usuários, incluindo autenticação criptografada (JWT/JWKS) e isolamento de dados por produto — os dados do MENTAL não são compartilhados com nenhum outro aplicativo da RhoneyInc.

---

## 10. Alterações nesta política

Esta Política de Privacidade pode ser atualizada periodicamente para refletir mudanças no aplicativo ou na legislação aplicável. A data da última atualização estará sempre indicada no topo deste documento. Mudanças significativas serão comunicadas dentro do próprio aplicativo.

---

## 11. Contato

Dúvidas, solicitações de acesso, correção ou exclusão de dados podem ser enviadas para: **rhoneyinc@gmail.com**

---

*Este documento foi elaborado com base nos princípios já estabelecidos em FAMILY_SAFETY.md e USER_PROFILE.md do projeto MENTAL. Campos entre colchetes [ ] precisam ser preenchidos por Rhoney antes da publicação final (e-mail de contato, data de publicação).*
