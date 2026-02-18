from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_ 
from typing import List
import models, schemas, database
import utils as auth

router = APIRouter(
    prefix="/messages",
    tags=["Messaging"]
)

@router.post("/", response_model=schemas.MessageOut, status_code=status.HTTP_201_CREATED)
async def send_message(
    msg: schemas.MessageCreate,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # 1. Scope Validation Logic
    if msg.scope == models.MessageScope.DIRECT:
        if not msg.recipient_id:
            raise HTTPException(status_code=400, detail="Recipient ID is required for Direct messages")
        # Check if recipient exists
        recipient = db.query(models.User).filter(models.User.id == msg.recipient_id).first()
        if not recipient:
            raise HTTPException(status_code=404, detail="Recipient not found")

    elif msg.scope == models.MessageScope.GROUP_SCHEDULE:
        if not msg.target_schedule_id:
            raise HTTPException(status_code=400, detail="Target Schedule ID is required for Group messages")
        # Validate schedule exists
        schedule = db.query(models.Schedule).filter(models.Schedule.id == msg.target_schedule_id).first()
        if not schedule:
            raise HTTPException(status_code=404, detail="Schedule not found")

    # 2. Permission Logic (Who can send what?)
    if current_user.role == models.Role.PARENT:
        if msg.scope not in [models.MessageScope.DIRECT]:
            raise HTTPException(status_code=403, detail="Parents can only send Direct messages (to Coaches/Admins)")
        # Ideally check if recipient is staff, but for now allow parent-parent (optional) or restrict to staff
    
    if msg.scope == models.MessageScope.BROADCAST_ALL and current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only Owners can send Broadcasts")

    # 3. Create Message
    new_message = models.Message(
        sender_id=current_user.id,
        content=msg.content,
        scope=msg.scope,
        recipient_id=msg.recipient_id,
        target_schedule_id=msg.target_schedule_id,
        image_url=msg.image_url
    )
    db.add(new_message)
    db.commit()
    db.refresh(new_message)
    
    # Enrich for response
    response = schemas.MessageOut.model_validate(new_message)
    response.sender_name = current_user.full_name
    return response

@router.get("/", response_model=List[schemas.MessageOut])
async def get_messages(
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Logic to fetch relevant messages
    
    # Base query: Always include messages sent BY me
    # OR messages sent TO me (Direct)
    base_filter = or_(
        models.Message.sender_id == current_user.id,
        models.Message.recipient_id == current_user.id
    )

    if current_user.role == models.Role.PARENT:
        # Parents also see:
        # 1. BROADCAST_ALL
        # 2. GROUP_SCHEDULE messages for schedules their children are enrolled in
        
        # Get list of schedule IDs where parent's children are enrolled (active)
        # Join User -> Member -> Enrollment
        enrolled_schedule_ids = [
            enrollment.schedule_id 
            for member in current_user.members 
            for enrollment in member.enrollments 
            if enrollment.active
        ]
        
        relevant_groups = and_(
            models.Message.scope == models.MessageScope.GROUP_SCHEDULE,
            models.Message.target_schedule_id.in_(enrolled_schedule_ids)
        )
        
        broadcasts = (models.Message.scope == models.MessageScope.BROADCAST_ALL)
        
        final_filter = or_(base_filter, relevant_groups, broadcasts)

    elif current_user.role in [models.Role.COACH, models.Role.OWNER]:
        # Staff see:
        # 1. INTERNAL_STAFF
        # 2. BROADCAST_ALL
        # 3. GROUP_SCHEDULE (All of them? Or just ones they coach? Let's say ALL for transparency in this MVP)
        
        internal = (models.Message.scope == models.MessageScope.INTERNAL_STAFF)
        broadcasts = (models.Message.scope == models.MessageScope.BROADCAST_ALL)
        groups = (models.Message.scope == models.MessageScope.GROUP_SCHEDULE)
        
        final_filter = or_(base_filter, internal, broadcasts, groups)
    
    else:
        final_filter = base_filter

    messages = db.query(models.Message).filter(final_filter).order_by(models.Message.sent_at.desc()).all()
    
    # Enrich sender names manually (simple way)
    results = []
    for m in messages:
        m_out = schemas.MessageOut.model_validate(m)
        m_out.sender_name = m.sender.full_name
        results.append(m_out)
        
    return results
