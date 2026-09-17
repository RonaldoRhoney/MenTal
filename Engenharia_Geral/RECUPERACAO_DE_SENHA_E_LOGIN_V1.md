# MENTAL — Recuperação de Senha e Fluxo de Login

**Status:** IMPLEMENTADO (14/09/2026) — seção 2.1 completa. Seção 2.2 investigada e reportada abaixo (nenhum código adicional necessário, ver "Achados da seção 2.2").

## Investigação (confirmando §3 do documento)

O Supabase Auth (já em uso — `client/lib/screens/login_screen.dart` fala com `Supabase.instance.client.auth` diretamente, sem passar pelo backend FastAPI) **já tem fluxo nativo completo de "password reset"**, exatamente como o documento previu: expiração de token, invalidação após uso, e resposta neutra quanto à existência do e-mail já vêm de fábrica do GoTrue — nada disso foi reimplementado do zero.

**Nenhuma configuração nova no Supabase Dashboard foi necessária**: o redirect usado pro e-mail de redefinição (`com.rhoneyinc.mental://login-callback`) é o MESMO já cadastrado em Authentication → URL Configuration pro login OAuth — o intent-filter do Android já casa por host, então serve pros dois fluxos sem mudança nenhuma em `AndroidManifest.xml` nem no Dashboard.

## O que foi implementado

- `client/lib/screens/forgot_password_screen.dart` (novo) — tela "Esqueci minha senha": pede o e-mail, chama `auth.resetPasswordForEmail`, mostra sempre a MESMA mensagem de confirmação (sucesso ou erro, e-mail cadastrado ou não) — nunca revela existência de conta.
- `client/lib/screens/reset_password_screen.dart` (novo) — tela "Nova senha": aberta automaticamente quando o link do e-mail traz `AuthChangeEvent.passwordRecovery`; chama `auth.updateUser` com a senha nova; ao concluir, desloga a sessão de recuperação temporária e volta pro login normal.
- `client/lib/main.dart` — intercepta `AuthChangeEvent.passwordRecovery` ANTES de tratar a sessão como login normal (achado importante: esse evento chega com uma sessão VÁLIDA, que sem essa interceptação entraria direto na Home com a senha antiga ainda ativa, sem forçar a redefinição).
- `client/lib/screens/login_screen.dart` — link "Esqueci minha senha" (só no modo entrar, nunca no modo criar conta).
- Teste de regressão: `test/login_screen_test.dart` (link aparece só no modo certo).

## Achados da seção 2.2 (revisão de segurança do login, sem mudança de código)

- **Neutralidade de erro (não revelar se o e-mail existe)**: já satisfeita por padrão. `login_screen.dart` só repassa `AuthException.message` direto do GoTrue, sem diferenciar "e-mail não existe" de "senha errada" — o Supabase já retorna a mesma mensagem genérica ("Invalid login credentials") pros dois casos.
- **Bloqueio/atraso após tentativas malsucedidas**: já coberto pelos limites padrão do Supabase Auth (GoTrue já aplica rate limiting nos próprios endpoints de autenticação, fora do controle do backend FastAPI do projeto — a autenticação nunca passa por lá). Nenhuma proteção adicional própria foi implementada aqui, seguindo a recomendação do próprio documento (§2.3: "priorizar essa integração antes de qualquer solução customizada").
- **Opcional, não bloqueante**: o e-mail de redefinição usa o template padrão do Supabase (texto em inglês, sem a identidade visual do MENTAL). Se Rhoney quiser a marca do app no e-mail, isso é customizável em Supabase Dashboard → Authentication → Email Templates → Reset Password — mudança de conteúdo/design, não de código do app.

---

## 1. Problema

O MENTAL não oferece, atualmente, nenhuma forma de o usuário recuperar o acesso à própria conta caso esqueça a senha. Isso é uma lacuna crítica de UX e de retenção — sem esse fluxo, qualquer usuário que esqueça a senha perde acesso permanente à conta (progresso, XP, MentalCoins, território, tudo), sem alternativa.

## 2. Escopo da funcionalidade

### 2.1 Recuperação de senha ("Esqueci minha senha")
- Tela de login deve ganhar um link/botão "Esqueci minha senha".
- Fluxo padrão: usuário informa e-mail cadastrado → sistema envia e-mail com link (ou código) de redefinição → usuário define nova senha → confirmação de sucesso → redirecionamento para login com a nova senha.
- O link/código de redefinição deve ter **expiração** (prazo a definir tecnicamente, mas um padrão de mercado como 30-60 minutos é razoável) — nunca permanecer válido indefinidamente.
- Mensagem de confirmação deve ser **neutra quanto à existência do e-mail no sistema** (não revelar se aquele e-mail está ou não cadastrado, por segurança — resposta genérica do tipo "se esse e-mail estiver cadastrado, você receberá um link" evita enumeração de contas por terceiros mal-intencionados).

### 2.2 Fluxo de login — pontos a revisar junto
Já que o login está sendo tocado, vale a auditoria/confirmação destes pontos, que provavelmente já existem mas devem ser confirmados:
- Tratamento de erro claro quando a senha está incorreta (sem revelar se o erro é "e-mail não existe" vs "senha errada" — mesma lógica de não vazar informação sobre contas existentes).
- Bloqueio ou atraso progressivo após múltiplas tentativas de login malsucedidas, como proteção básica contra força bruta (se ainda não existir).
- Confirmar se o Supabase Auth (usado como base de autenticação do projeto) já oferece nativamente parte dessa funcionalidade de recuperação de senha — o que pode reduzir drasticamente o esforço de implementação, bastando expor a funcionalidade já existente da plataforma na UI do app, em vez de construir do zero.

## 3. Escopo técnico (a investigar e implementar por Claude Code)

- Verificar se o Supabase Auth, já em uso no projeto, possui fluxo nativo de "password reset" (é comum em provedores de autenticação como esse) — priorizar essa integração antes de qualquer solução customizada, por ser mais rápida e mais segura (evita reinventar criptografia/expiração de token).
- Implementar a tela de "Esqueci minha senha" na UI (Flutter), incluindo os três estados: solicitação de e-mail, aguardando confirmação, e formulário de nova senha.
- Configurar o envio de e-mail transacional (via Supabase ou serviço de e-mail já usado no projeto, se houver) com o link/código de redefinição.
- Garantir que o link de redefinição expire corretamente e que tokens usados não possam ser reutilizados.
- Revisar e confirmar os pontos de segurança de login listados na seção 2.2, reportando a Rhoney o estado atual de cada um antes de qualquer mudança adicional.

## 4. Critério de aceite

- Usuário consegue, a partir da tela de login, solicitar redefinição de senha informando o e-mail cadastrado.
- E-mail de redefinição chega corretamente, com link/código funcional e com expiração configurada.
- Usuário consegue definir nova senha e fazer login com ela logo em seguida.
- Sistema não revela se um e-mail está ou não cadastrado, em nenhuma etapa do fluxo (nem no "esqueci senha", nem no login comum).
- Testes de regressão confirmando que o fluxo de login e cadastro existentes continuam funcionando normalmente após a mudança.
