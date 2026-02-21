from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional # [NOVO] Bitno za listu korisnika
import models, schemas, database
import utils as auth

router = APIRouter(
    prefix="/users",
    tags=["Users"]
)

# --- 1. STARI KOD: Saznaj ko sam ja (Bitno za AuthProvider) ---
@router.get("/me", response_model=schemas.UserOut)
async def read_users_me(current_user: models.User = Depends(auth.get_current_active_user)):
    return current_user

# --- 1b. Promena lozinke (Change Password) ---
@router.put("/me/password")
def change_password(
    payload: schemas.PasswordChange,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    if not auth.verify_password(payload.old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Stara lozinka nije tačna.")

    current_user.hashed_password = auth.get_password_hash(payload.new_password)
    db.commit()
    return {"detail": "Lozinka je uspešno promenjena."}

# --- 2. STARI KOD: Kreiraj korisnika (Bitno za pravljenje Trenera/Roditelja) ---
@router.post("/", response_model=schemas.UserOut)
def create_user(user: schemas.UserCreate, db: Session = Depends(auth.get_db)):
    # 1. Provera da li email vec postoji
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # 2. Hesiranje lozinke
    hashed_password = auth.get_password_hash(user.password)
    
    # 3. Kreiranje korisnika
    db_user = models.User(
        email=user.email,
        hashed_password=hashed_password,
        full_name=user.full_name,
        phone_number=user.phone_number, # Dodao sam ovo jer postoji u modelu
        role=user.role,
        is_active=True
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user

# --- 3. NOVI KOD: Izlistaj korisnike (Bitno da Owner vidi trenere) ---
@router.get("/", response_model=List[schemas.UserOut])
async def read_users(
    role: Optional[str] = None, # Možeš da filtriraš ?role=COACH
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Samo Owner i Trener mogu da gledaju liste korisnika
    if current_user.role not in [models.Role.OWNER, models.Role.COACH]:
        raise HTTPException(status_code=403, detail="Not authorized")

    query = db.query(models.User)
    
    if role:
        query = query.filter(models.User.role == role)
        
    users = query.offset(skip).limit(limit).all()
    return users

# --- 4. DELETE: Obriši korisnika (Staff) ---
@router.delete("/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    if current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only Owner can delete users")

    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot delete yourself")

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # --- Coach cleanup: nullify references before deleting ---
    if user.role == models.Role.COACH:
        db.query(models.Schedule).filter(
            models.Schedule.coach_id == user_id
        ).update({"coach_id": None})

        db.query(models.Attendance).filter(
            models.Attendance.coach_id == user_id
        ).update({"coach_id": None})

        db.query(models.MemberSkill).filter(
            models.MemberSkill.coach_id == user_id
        ).update({"coach_id": None})

    # --- Clean up messages sent/received by this user ---
    db.query(models.Message).filter(
        models.Message.sender_id == user_id
    ).delete()
    db.query(models.Message).filter(
        models.Message.recipient_id == user_id
    ).update({"recipient_id": None})

    db.delete(user)
    db.commit()
    return {"detail": "User deleted"}

# --- 5. ADMIN CREATE: Owner kreira korisnika (Trenera/Roditelja) ---
@router.post("/admin-create", response_model=schemas.UserOut, status_code=status.HTTP_201_CREATED)
def admin_create_user(
    user: schemas.UserCreate,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    if current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only Owner can create users")

    existing = db.query(models.User).filter(models.User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = auth.get_password_hash(user.password)
    db_user = models.User(
        email=user.email,
        hashed_password=hashed_password,
        full_name=user.full_name,
        phone_number=user.phone_number,
        role=user.role,
        is_active=True,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user