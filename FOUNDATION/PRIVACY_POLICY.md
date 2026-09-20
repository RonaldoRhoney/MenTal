# Política de Privacidade — MENTAL

**Última atualização:** 20 de setembro de 2026

Esta Política de Privacidade descreve como o aplicativo **MENTAL**, desenvolvido por **RhoneyInc**, coleta, usa e protege as informações dos usuários.

O MENTAL é um aplicativo de desafios cognitivos gamificados, destinado **exclusivamente a maiores de 18 anos** (MENTAL-DIR-001). O acesso exige confirmação de maioridade antes de qualquer outro uso do app. Esta política segue as exigências da **Lei Geral de Proteção de Dados (LGPD)**.

Este é o texto-fonte deste documento; a versão hospedada e vinculada dentro do app está em `store_assets/mental-privacidade.html`, publicada em https://ronaldorhoney.github.io/MenTal/ — as duas devem ser mantidas idênticas em conteúdo.

---

## 1. Quem somos

O MENTAL é desenvolvido e mantido por **RhoneyInc**, estúdio de produtos digitais sediado em Belém, Pará, Brasil.

**Contato para questões de privacidade:** rhoneyinc@gmail.com

---

## 2. Quais dados coletamos

### 2.1 Dados obrigatórios (necessários para o funcionamento do app)
- **E-mail** — usado para criação de conta, login e recuperação de acesso (via Supabase Auth).
- **Nickname (apelido)** — usado para identificação do jogador dentro do app (ranking, amigos, badges).
- **Confirmação de maioridade** — o usuário confirma ter 18 anos ou mais antes de qualquer outro uso do app. O MENTAL não é destinado a menores de idade.
- **Nome real** — obrigatório para liberar o jogo. Como o MENTAL é exclusivo para maiores de 18 anos, o nome real é **exibido publicamente** ao lado da foto de perfil em telas sociais do app (Amigos, Ranking, Batalhas), reforçando a seriedade da comunidade.
- **Foto de perfil** — obrigatória para liberar o jogo. É uma foto real enviada pelo próprio usuário (câmera ou galeria), **não um avatar ilustrado**. Você decide se sua foto fica pública (visível para outros usuários) ou privada, e pode mudar essa escolha a qualquer momento na tela de Perfil.
- **País, estado e cidade** — obrigatórios para liberar o jogo. Não coletamos localização geográfica precisa (GPS); são campos de texto informados pelo próprio usuário.
- **Faixa etária** — obrigatória para liberar o jogo (faixas amplas: 18-25, 26-35, 36-45, 46+). Não coletamos data de nascimento nem documento de identidade — a confirmação de idade é autodeclarada.

### 2.2 Dados opcionais (o usuário escolhe se preenche)
- **Gênero** — campo opcional (masculino, feminino, não-binário, prefiro não informar).

### 2.3 Dados de progresso e uso do jogo
- Pontuação (XP), nível, territórios conquistados, badges/conquistas, estatísticas de desempenho (acertos, erros, sequência de dias jogados).
- Contagem de passos (via sensor de hardware do dispositivo, `TYPE_STEP_COUNTER`) — coletada apenas se o usuário conceder a permissão correspondente, usada exclusivamente para a funcionalidade de gamificação por movimento dentro do app. **Não coletamos dados de localização GPS associados aos passos.**
- Preferências de notificação (quais tipos de notificação o usuário optou por receber).
- **Histórico de notificações** — a Central de Notificações do app guarda, por até 30 dias, o conteúdo das notificações recebidas (ex.: "Fulano te desafiou para uma Batalha", "Fulano te mandou uma torcida"), com estado de lida/não lida. Visível só para o próprio destinatário, nunca para outros usuários.
- **Token de notificação push (FCM)** — identificador técnico do aparelho, guardado no seu perfil para entregar notificações; removido quando expira ou quando a conta é excluída.
- **Registro de uso** — a data em que você abre o app (bônus de login diário e sequência de dias), a última atividade, as respostas enviadas (acerto/erro, dicas usadas e tempo de resposta), as recompensas recebidas e o histórico de transações de MentalCoins. Usados para pontuação, sequência, ranking, dificuldade adaptativa e prevenção de fraude.
- **Passos por dia** — o total de cada dia (ciclo de 24 horas, horário de Brasília) e a evolução ao longo do dia, enviados quando você ativa o Movimento.
- **Amizades, bloqueios e denúncias** — sua lista de amigos, os usuários que você bloqueou e as denúncias que enviou (visíveis apenas à moderação).
- **Sugestões** — termos pesquisados sem resultado (sugestão de conteúdo) e opiniões sobre níveis de dificuldade.
- **Respostas no mural de feedback** — o mural é aberto: qualquer usuário comenta e responde. Comentários e respostas são **públicos** e mostram seu nome real; você pode apagar as suas respostas.
- **Comentários de feedback** — mensagens que o usuário opta por enviar na tela de Feedback do app são **públicas**, visíveis a todos os usuários junto com o nome real de quem enviou (ou o apelido, se o nome real ainda não tiver sido preenchido), e outros usuários podem reagir a elas (curtir/amei).

### 2.4 Dados de autenticação social (opcional)
- Se o usuário optar por entrar com **Google** ou **Facebook**, recebemos apenas as informações básicas de identificação fornecidas pelo provedor (e-mail e identificador de conta), conforme autorizado pelo usuário no momento do login.

### 2.5 Perfil Público e funcionalidades sociais

O MENTAL tem um conjunto de funcionalidades sociais que tornam parte do seu perfil visível para outros usuários do app, **independente de vínculo de amizade prévio**:

- **Perfil Público** — nome real, foto de perfil (se você a mantiver pública), nível, XP total, badges/conquistas, sequência de dias jogados (streak), progresso nos Mundos e número de "fãs" (seguidores) ficam visíveis a **qualquer usuário autenticado no app** que acesse seu perfil — por exemplo, ao tocar em um nome no Ranking. Não é preciso ser seu amigo para ver essas informações.
- **Seguir / Fã** — qualquer usuário pode optar por "seguir" outro dentro do app, sem necessidade de aceite da pessoa seguida. Quem segue passa a ver os eventos de conquista dessa pessoa no Feed.
- **Feed de conquistas** — exibe eventos gerados automaticamente pelo sistema (ex.: subida de nível, sequência de dias, recorde pessoal) para quem você segue. Esses eventos nunca contêm texto livre digitado pelo usuário.
- **Torcida** — outros usuários podem enviar reações de incentivo ("torcida") para o seu perfil, dentro de limites diários por pessoa.
- **MentalCoins** — moeda virtual interna do app, obtida jogando (ranking semanal de XP e passos, login diário, marcos de sequência de dias, dias ativos de Movimento, convites e outras ações) e usada dentro do MENTAL em itens cosméticos, boost temporário de XP e reparo de sequência. Não tem valor monetário, não pode ser comprada, convertida em dinheiro real nem sacada.

Você pode bloquear outro usuário a qualquer momento; o bloqueio impede o acesso ao seu Perfil Público, desfaz relações de amizade e de Seguir/Fã existentes entre as duas contas, e impede o envio de Torcida.

---

## 3. O que NÃO coletamos

- **Não coletamos número de telefone.**
- **Não coletamos localização GPS/geolocalização precisa.**
- **Não coletamos data de nascimento nem documento de identidade** — a confirmação de maioridade é autodeclarada.
- **Não exibimos publicidade personalizada** — atualmente, o MENTAL **não exibe nenhum tipo de publicidade** (aplicativo 100% gratuito).

---

## 4. Como usamos os dados coletados

Os dados são usados exclusivamente para:
- Autenticar o usuário e manter sua conta segura.
- Exibir seu progresso, conquistas e desempenho dentro do app.
- Personalizar a dificuldade dos desafios de acordo com o desempenho individual.
- Enviar notificações que o usuário optou por receber.
- Viabilizar as funcionalidades sociais do app: ranking, amigos, desafios assíncronos, Perfil Público, Feed de conquistas, Seguir/Fã, Torcida e MentalCoins — ver o detalhamento de visibilidade de cada uma na seção 2.5.

**Não vendemos, alugamos ou compartilhamos dados pessoais com terceiros para fins de publicidade.**

---

## 5. Restrição de idade e conteúdo gerado por usuários

O MENTAL é destinado exclusivamente a usuários com 18 anos ou mais:
- O acesso ao app exige confirmação de maioridade antes de qualquer outro uso.
- O MENTAL não coleta, nem tenta coletar, dados de usuários que não confirmem ter 18 anos ou mais.

O MENTAL tem conteúdo gerado por usuários (UGC): foto de perfil e comentários públicos de feedback. Para manter esse conteúdo seguro:
- A visibilidade da foto de perfil (pública ou privada) é escolhida pelo próprio usuário, mudável a qualquer momento.
- Usuários podem denunciar perfis ou conteúdo impróprio diretamente no app; denúncias são revisadas pela equipe do MENTAL, que pode ocultar uma foto ou conteúdo em resposta a uma denúncia procedente.

---

## 6. Compartilhamento de dados

Utilizamos os seguintes serviços de terceiros para operar o aplicativo, cada um recebendo apenas o dado estritamente necessário para sua função técnica:

- **Supabase** — armazenamento de dados de conta e progresso do jogo, autenticação, e armazenamento das fotos de perfil enviadas.
- **Google Firebase Cloud Messaging (FCM)** — exclusivamente para entrega de notificações push; não é utilizado como banco de dados nem para fins de publicidade.
- **Google Sign-In** — autenticação opcional via conta Google, apenas quando o usuário escolhe esse método de login.
- **Render** — hospedagem do servidor da aplicação, que processa as requisições do app.
- **Facebook Login** — autenticação opcional, apenas quando o usuário escolhe esse método de login.
- **GitHub Pages** — hospeda esta página de política, sem receber dados do app.

Nenhum desses serviços recebe dados além do estritamente necessário para sua função, e nenhum é utilizado para publicidade direcionada.

---

## 7. Retenção e exclusão de dados

- Os dados do usuário são mantidos enquanto a conta estiver ativa. As notificações da Central são apagadas após 30 dias.
- **Excluir pelo app (imediato):** Ajustes › "Excluir minha conta". A exclusão é definitiva.
- **Excluir por e-mail:** envie para **rhoneyinc@gmail.com**, a partir do endereço cadastrado no app, com o assunto "Exclusão de conta MENTAL".
- A exclusão remove permanentemente: e-mail de acesso, apelido, nome real, foto de perfil, localização (país/estado/cidade), gênero, faixa etária, progresso/XP, badges, amigos, bloqueios, denúncias enviadas, histórico de tentativas, registros de recompensas e de login diário, MentalCoins, passos e ciclos de Movimento, notificações, eventos do Feed, relações de Seguir/Fã, token de notificação, convites e as suas respostas no mural de feedback. **Exceção:** comentários de feedback, opiniões sobre níveis e sugestões de conteúdo enviados pelo usuário não são apagados — são **anonimizados** (desvinculados da sua identidade) e permanecem sem nenhuma associação com você, preservando seu valor como registro de melhoria do app.

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
