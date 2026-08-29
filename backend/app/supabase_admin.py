"""
Chamadas administrativas ao Supabase (Storage + Auth) usando
SUPABASE_SERVICE_ROLE_KEY — credencial de privilégio total, nunca a
mesma chave publishable usada pelo client. Usa httpx direto contra a
API REST/Storage/Auth do Supabase em vez do SDK oficial (supabase-py):
o projeto já depende de httpx, e o SDK completo traria clientes
(postgrest, realtime) que o backend não usa em nada — mesmo espírito de
menor dependência já seguido no resto do projeto.

Achado de auditoria de segurança (28/08/2026): sem essas duas
capacidades (URL assinada + exclusão real de usuário), o bucket de
fotos ficava público (violando DIR-001/POL-002, que exigem bucket
privado) e não havia como excluir de verdade a conta de um usuário
(LGPD/DIR-001 item 5) — só zerar campos manualmente, deixando o login
intacto. Com SUPABASE_SERVICE_ROLE_KEY configurado, os dois passam a
ser possíveis de verdade.

Todas as funções aqui silenciosamente viram no-op/retornam None se
SUPABASE_SERVICE_ROLE_KEY não estiver configurado (dev local sem
Supabase, ou enquanto a variável não foi cadastrada em produção) —
nunca derruba o request principal por causa de uma chamada
administrativa auxiliar.
"""

import httpx

from . import config

_TIMEOUT = 8.0


def _admin_headers() -> dict[str, str] | None:
    if not config.SUPABASE_URL or not config.SUPABASE_SERVICE_ROLE_KEY:
        return None
    return {
        "Authorization": f"Bearer {config.SUPABASE_SERVICE_ROLE_KEY}",
        "apikey": config.SUPABASE_SERVICE_ROLE_KEY,
    }


def create_signed_photo_url(path: str, expires_in_seconds: int = 3600) -> str | None:
    """
    URL temporária de leitura pro bucket privado `profile-photos`
    (storage.objects não tem mais policy de leitura pública — só o
    dono, via RLS, ou quem tiver uma URL assinada gerada aqui). None se
    a credencial de admin não estiver configurada (fallback: chamador
    trata como "foto indisponível", nunca quebra a resposta principal).
    """
    headers = _admin_headers()
    if headers is None:
        return None
    try:
        resp = httpx.post(
            f"{config.SUPABASE_URL}/storage/v1/object/sign/profile-photos/{path}",
            headers=headers,
            json={"expiresIn": expires_in_seconds},
            timeout=_TIMEOUT,
        )
        resp.raise_for_status()
        signed_path = resp.json().get("signedURL")
        if not signed_path:
            return None
        return f"{config.SUPABASE_URL}/storage/v1{signed_path}"
    except httpx.HTTPError:
        return None


def delete_photo_object(path: str) -> None:
    """Remove o arquivo do bucket — melhor esforço, nunca lança."""
    headers = _admin_headers()
    if headers is None:
        return
    try:
        httpx.request(
            "DELETE",
            f"{config.SUPABASE_URL}/storage/v1/object/profile-photos/{path}",
            headers=headers,
            timeout=_TIMEOUT,
        )
    except httpx.HTTPError:
        pass


def delete_auth_user(user_id: str) -> bool:
    """
    Exclusão real da conta no Supabase Auth (auth.users) — todas as
    tabelas de mental.* referenciam auth.users(id) com
    `on delete cascade` (migrations/001_initial_schema.sql), então isto
    sozinho já apaga profile/attempts/friendships/etc. em cascata no
    Postgres. Retorna False (nunca lança) se a credencial de admin não
    estiver configurada ou a chamada falhar — o chamador decide como
    reagir (ex.: 501 informando que a exclusão completa ainda não está
    disponível neste ambiente).
    """
    headers = _admin_headers()
    if headers is None:
        return False
    try:
        resp = httpx.request(
            "DELETE",
            f"{config.SUPABASE_URL}/auth/v1/admin/users/{user_id}",
            headers=headers,
            timeout=_TIMEOUT,
        )
        return resp.status_code in (200, 204)
    except httpx.HTTPError:
        return False
