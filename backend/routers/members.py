from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
import models, schemas, auth, database

router = APIRouter(
    prefix="/members",
    tags=["members"]
)

# 1. DOHVATI MOJU DECU (GET)
@router.get("/mine", response_model=List[schemas.MemberOut])
def get_my_members(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Vraća samo decu gde je parent_id jednak ID-u ulogovanog korisnika
    return db.query(models.Member).options(joinedload(models.Member.enrollments)).filter(models.Member.parent_id == current_user.id).all()

# 2. DODAJ NOVO DETE (POST)
@router.post("/", response_model=schemas.MemberOut, status_code=status.HTTP_201_CREATED)
def create_member(
    member: schemas.MemberCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Provera prava pristupa
    if current_user.role != models.Role.PARENT and current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only parents can add members")

    # Kreiranje člana
    new_member = models.Member(
        **member.dict(), # Ili member.model_dump() ako koristiš Pydantic v2
        parent_id=current_user.id,
        active=True
    )
    db.add(new_member)
    db.commit()
    db.refresh(new_member)
    return new_member

# 2b. ADMIN DODAJ DETE (POST) — Owner specifies parent_id
class AdminMemberCreate(schemas.MemberBase):
    parent_id: int

@router.post("/admin-create", response_model=schemas.MemberOut, status_code=status.HTTP_201_CREATED)
def admin_create_member(
    member: AdminMemberCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    if current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only Owner can use admin create")

    parent = db.query(models.User).filter(models.User.id == member.parent_id).first()
    if not parent:
        raise HTTPException(status_code=404, detail="Parent not found")

    new_member = models.Member(
        full_name=member.full_name,
        date_of_birth=member.date_of_birth,
        notes=member.notes,
        parent_id=member.parent_id,
        active=True,
    )
    db.add(new_member)
    db.commit()
    db.refresh(new_member)
    return new_member

# 3. AZURIRAJ DETE (PUT)
@router.put("/{member_id}", response_model=schemas.MemberOut)
def update_member(
    member_id: int,
    member_update: schemas.MemberCreate, # Reusing Create schema for simplicity, or create specific Update schema
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # 1. Fetch member
    db_member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not db_member:
        raise HTTPException(status_code=404, detail="Member not found")
        
    # 2. Authorization
    if current_user.role != models.Role.OWNER and db_member.parent_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this member")
    
    # 3. Update fields
    db_member.full_name = member_update.full_name
    db_member.date_of_birth = member_update.date_of_birth
    db_member.notes = member_update.notes
    
    db.commit()
    db.refresh(db_member)
    return db_member

# 4. DOHVATI SVE ČLANOVE (Owner/Coach only)
@router.get("/all")
def get_all_members(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    if current_user.role not in [models.Role.OWNER, models.Role.COACH]:
        raise HTTPException(status_code=403, detail="Not authorized")

    members = (
        db.query(models.Member)
        .options(joinedload(models.Member.parent))
        .order_by(models.Member.full_name)
        .all()
    )

    return [
        {
            "id": m.id,
            "full_name": m.full_name,
            "date_of_birth": str(m.date_of_birth) if m.date_of_birth else None,
            "parent_name": m.parent.full_name if m.parent else None,
            "parent_phone": m.parent.phone_number if m.parent else None,
            "notes": m.notes,
            "active": m.active,
        }
        for m in members
    ]

# 5. OBRIŠI ČLANA — Smart Deletion with Orphan Parent Cleanup
@router.delete("/{member_id}")
def delete_member(
    member_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    if current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only Owner can delete members")

    member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")

    parent_id = member.parent_id

    # 1. Delete related records first
    db.query(models.Attendance).filter(models.Attendance.member_id == member_id).delete()
    db.query(models.Enrollment).filter(models.Enrollment.member_id == member_id).delete()
    db.query(models.MemberSkill).filter(models.MemberSkill.member_id == member_id).delete()

    # 2. Delete the member
    db.delete(member)
    db.flush()

    # 3. Orphan check — does this parent have any other children?
    remaining = db.query(models.Member).filter(
        models.Member.parent_id == parent_id
    ).count()

    parent_deleted = False
    if remaining == 0 and parent_id:
        parent = db.query(models.User).filter(models.User.id == parent_id).first()
        if parent and parent.role == models.Role.PARENT:
            db.delete(parent)
            parent_deleted = True

    db.commit()
    return {"detail": "Member deleted", "parent_deleted": parent_deleted}