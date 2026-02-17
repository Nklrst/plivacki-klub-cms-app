from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import date
from .. import models, schemas, auth, database

router = APIRouter(
    prefix="/skills",
    tags=["Skills & Progress"]
)

# 1. Get All Skills (Public/Authenticated)
@router.get("/", response_model=List[schemas.SkillOut])
async def read_skills(
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    return db.query(models.Skill).order_by(models.Skill.display_order).all()

@router.post("/", response_model=schemas.SkillOut, status_code=status.HTTP_201_CREATED)
async def create_skill(
    skill: schemas.SkillCreate,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    if current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only Owners can create skills")
    
    # Check for duplicate
    existing = db.query(models.Skill).filter(models.Skill.name == skill.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Skill with this name already exists")

    new_skill = models.Skill(**skill.model_dump())
    db.add(new_skill)
    db.commit()
    db.refresh(new_skill)
    return new_skill

# 2. Award Skill (Coach/Owner Only)
@router.post("/members/{member_id}", response_model=schemas.MemberSkillOut)
async def award_skill(
    member_id: int,
    skill_data: schemas.MemberSkillBase,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # RBAC
    if current_user.role not in [models.Role.COACH, models.Role.OWNER]:
        raise HTTPException(status_code=403, detail="Only Coaches can award skills")
    
    # Check Member
    member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")

    # Check Skill
    skill = db.query(models.Skill).filter(models.Skill.id == skill_data.skill_id).first()
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")

    # Check if already acquired
    existing = db.query(models.MemberSkill).filter(
        models.MemberSkill.member_id == member_id,
        models.MemberSkill.skill_id == skill_data.skill_id
    ).first()
    
    if existing:
        return existing

    # Award
    new_achievement = models.MemberSkill(
        member_id=member_id,
        skill_id=skill_data.skill_id,
        acquired_at=date.today(),
        coach_id=current_user.id
    )
    db.add(new_achievement)
    db.commit()
    db.refresh(new_achievement)
    return new_achievement

# 3. Revoke Skill (Coach/Owner Only)
@router.delete("/members/{member_id}/{skill_id}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_skill(
    member_id: int,
    skill_id: int,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    if current_user.role not in [models.Role.COACH, models.Role.OWNER]:
        raise HTTPException(status_code=403, detail="Only Coaches can revoke skills")

    achievement = db.query(models.MemberSkill).filter(
        models.MemberSkill.member_id == member_id,
        models.MemberSkill.skill_id == skill_id
    ).first()
    
    if achievement:
        db.delete(achievement)
        db.commit()
    
    return None

# 4. Get Member Skills (Parent View)
@router.get("/members/{member_id}", response_model=List[schemas.MemberSkillOut])
async def get_member_skills(
    member_id: int,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Check Member
    member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")

    # Security: Parent can only view own child
    if current_user.role == models.Role.PARENT and member.parent_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this member's skills")

    return db.query(models.MemberSkill).filter(models.MemberSkill.member_id == member_id).all()

# 5. Get Full Skills Status for a Member (Coach Dialog)
@router.get("/members/{member_id}/status", response_model=List[schemas.MemberSkillStatus])
async def get_member_skills_status(
    member_id: int,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Returns ALL skills with is_mastered flag for the Coach dialog."""
    member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")

    # Get all base skills
    all_skills = db.query(models.Skill).order_by(models.Skill.display_order).all()

    # Get this member's acquired skill IDs
    acquired = db.query(models.MemberSkill.skill_id).filter(
        models.MemberSkill.member_id == member_id
    ).all()
    acquired_ids = {row[0] for row in acquired}

    return [
        schemas.MemberSkillStatus(
            skill_id=skill.id,
            skill_name=skill.name,
            is_mastered=skill.id in acquired_ids
        )
        for skill in all_skills
    ]

# 6. Batch Update Member Skills (Coach Dialog Save)
@router.put("/members/{member_id}/batch", status_code=status.HTTP_200_OK)
async def batch_update_member_skills(
    member_id: int,
    data: schemas.MemberSkillBatchUpdate,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Replaces all member skills with the provided list of mastered skill IDs."""
    if current_user.role not in [models.Role.COACH, models.Role.OWNER]:
        raise HTTPException(status_code=403, detail="Only Coaches/Owners can update skills")

    member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")

    # Delete all existing records for this member
    db.query(models.MemberSkill).filter(
        models.MemberSkill.member_id == member_id
    ).delete()

    # Insert new records for mastered skills
    for skill_id in data.mastered_skill_ids:
        new_record = models.MemberSkill(
            member_id=member_id,
            skill_id=skill_id,
            acquired_at=date.today(),
            coach_id=current_user.id
        )
        db.add(new_record)

    db.commit()
    return {"message": "Skills updated successfully"}
