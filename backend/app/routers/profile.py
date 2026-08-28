"""
Perfil do usuário (USER_PROFILE.md, aprovado; revisado 2026-08-26).
avatar_id (deprecated)/location_* continuam opcionais, nunca bloqueiam o
uso do app.

Cadastro mínimo obrigatório (decisão de Rhoney, 2026-08-26): nome, país,
cidade, gênero e faixa etária passam a ser exigidos antes do usuário
jogar — USER_PROFILE.md §1/§3 bloqueava especificamente "cidade exata"
por risco de localizar um menor, mas essa restrição foi motivada pelo
público misto de antes da DIR-001 (MENTAL agora é exclusivo pra maiores
de 18 anos). onboarding_completed_at é marcado automaticamente aqui,
nunca pelo client, na primeira vez que os 5 campos chegam preenchidos
juntos — mesmo princípio de "backend é sempre autoridade" já usado em
todo o resto do MENTAL.

Upload de foto real (revisão 26/08/2026): substitui os avatares emoji.
real_name e photo_url (só se aprovada) agora aparecem publicamente em
FriendOut/RankingEntry/BattleOut (services.py) — reversão explícita da
regra anterior de "nome real nunca público". Toda foto nova nasce
'pending' (fail-closed, USER_PROFILE.md §3.1) até um admin aprovar via
/admin/profile-photos.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import config, models, schemas, services
from ..auth import get_current_user_id, require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()

_ALLOWED_PHOTO_EXTENSIONS = (".jpg", ".jpeg", ".png", ".webp")


def _is_valid_photo_url(url: str, user_id: str) -> bool:
    """
    Validação leve, só de forma da URL — confirma que aponta pro bucket
    público esperado do próprio projeto Supabase, pra dentro da PRÓPRIA
    pasta do usuário autenticado (mesma regra que a policy de escrita do
    Storage já aplica: auth.uid()::text = (storage.foldername(name))[1]),
    e tem uma extensão de imagem permitida. NÃO inspeciona o conteúdo
    real do arquivo (magic bytes) — validação de conteúdo de verdade
    ficaria a cargo de uma Storage Edge Function/webhook, fora do escopo
    desta etapa.

    Achado de auditoria de segurança (28/08/2026): antes só conferia o
    prefixo do bucket + extensão — um usuário podia mandar
    `PUT /profile {"photo_url": ".../profile-photos/{uid_de_outro}/photo.jpg"}`
    e, depois de aprovado pelo admin, passar a exibir a foto de outra
    pessoa como se fosse sua no ranking global.

    O client anexa `?t=<timestamp>` (cache-busting: mesmo nome de arquivo
    é reaproveitado a cada upload via upsert, então sem isso o
    Image.network do Flutter mostraria a foto antiga em cache) — a
    extensão e a pasta são checadas só na parte de path, antes da
    querystring.
    """
    if config.SUPABASE_URL is None:
        # dev local sem Supabase configurado — ainda assim exige que a
        # URL aponte pra pasta do próprio usuário, checagem que não
        # depende de SUPABASE_URL estar setado.
        expected_prefix = f"/profile-photos/{user_id}/"
    else:
        expected_prefix = f"{config.SUPABASE_URL}/storage/v1/object/public/profile-photos/{user_id}/"
    path = url.split("?", 1)[0]
    return expected_prefix in url and path.lower().endswith(_ALLOWED_PHOTO_EXTENSIONS)


def _profile_out(profile: models.Profile) -> schemas.ProfileOut:
    return schemas.ProfileOut(
        nickname=profile.nickname,
        avatar_id=profile.avatar_id,
        real_name=profile.real_name,
        photo_url=profile.photo_url,
        photo_moderation_status=profile.photo_moderation_status,
        location_state=profile.location_state,
        location_country=profile.location_country,
        location_public=profile.location_public,
        age_confirmed_at=profile.age_confirmed_at,
        city=profile.city,
        gender=profile.gender,
        age_range=profile.age_range,
        onboarding_completed_at=profile.onboarding_completed_at,
    )


@router.get("/profile", response_model=schemas.ProfileOut)
def get_profile(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    # Fica de fora do require_age_confirmed_user_id de propósito — é a
    # própria chamada que o client usa (main.dart::_checkProfileStatus)
    # pra decidir SE mostra a tela de confirmação de maioridade. Exigir
    # a confirmação aqui criaria um 403 antes do usuário conseguir
    # confirmar a idade.
    profile = services.get_or_create_profile(db, user_id)
    return _profile_out(profile)


@router.put("/profile", response_model=schemas.ProfileOut)
def update_profile(
    body: schemas.UpdateProfileRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    profile = services.get_or_create_profile(db, user_id)
    profile.avatar_id = body.avatar_id
    profile.real_name = body.real_name
    profile.location_state = body.location_state
    profile.location_country = body.location_country
    # Preencher ≠ exibir automaticamente (§4 do documento) — location_public
    # é um campo opcional DENTRO do opcional, sempre explícito do usuário.
    profile.location_public = body.location_public
    profile.city = body.city
    profile.gender = body.gender
    profile.age_range = body.age_range

    if body.photo_url is not None and body.photo_url != profile.photo_url:
        if not _is_valid_photo_url(body.photo_url, user_id):
            raise HTTPException(
                status_code=422,
                detail={"error": {"code": "INVALID_PHOTO_URL", "message": "URL de foto inválida"}},
            )
        profile.photo_url = body.photo_url
        profile.photo_moderation_status = "pending"

    mandatory_fields = [body.real_name, body.location_country, body.city, body.gender, body.age_range]
    if profile.onboarding_completed_at is None and all(f is not None and f != "" for f in mandatory_fields):
        profile.onboarding_completed_at = utcnow()

    db.commit()
    return _profile_out(profile)


@router.get("/admin/profile-photos", response_model=list[schemas.AdminPendingPhotoItem])
def list_pending_profile_photos(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    admin_profile = db.get(models.Profile, user_id)
    if admin_profile is None or admin_profile.role != "admin":
        raise HTTPException(status_code=403, detail={"error": {"code": "ADMIN_ONLY", "message": "Restricted to admin accounts"}})

    rows = (
        db.execute(select(models.Profile).where(models.Profile.photo_moderation_status == "pending"))
        .scalars()
        .all()
    )
    return [
        schemas.AdminPendingPhotoItem(user_id=row.user_id, nickname=row.nickname, photo_url=row.photo_url)
        for row in rows
        if row.photo_url is not None
    ]


@router.post("/admin/profile-photos/{target_user_id}/moderate")
def moderate_profile_photo(
    target_user_id: str,
    body: schemas.ModerateProfilePhotoRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    admin_profile = db.get(models.Profile, user_id)
    if admin_profile is None or admin_profile.role != "admin":
        raise HTTPException(status_code=403, detail={"error": {"code": "ADMIN_ONLY", "message": "Restricted to admin accounts"}})

    target_profile = db.get(models.Profile, target_user_id)
    if target_profile is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "PROFILE_NOT_FOUND", "message": target_user_id}})

    target_profile.photo_moderation_status = "approved" if body.approved else "rejected"
    db.commit()
    return {"ok": True}
