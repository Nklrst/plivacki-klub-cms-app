from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import date
import models, schemas, auth, database

router = APIRouter(
    prefix="/attendance",
    tags=["Attendance"]
)

# 1. Get Attendance Sheet (List of members in a schedule for a specific date)
@router.get("/schedule/{schedule_id}/date/{date_str}", response_model=List[schemas.AttendanceOut])
async def get_attendance_sheet(
    schedule_id: int,
    date_str: date,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    # Provera: Da li schedule postoji?
    schedule = db.query(models.Schedule).filter(models.Schedule.id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Schedule not found")

    # 1. Nađi svu decu koja su UPISANA (Enrolled) u ovaj termin
    enrollments = db.query(models.Enrollment).filter(
        models.Enrollment.schedule_id == schedule_id,
        models.Enrollment.active == True
    ).all()

    # 2. Nađi postojeće zapise o prisustvu za ovaj datum (ako ih ima)
    existing_attendance = db.query(models.Attendance).filter(
        models.Attendance.schedule_id == schedule_id,
        models.Attendance.date == date_str
    ).all()
    
    # Pretvaramo u mapu radi brže pretrage: {member_id: AttendanceRecord}
    attendance_map = {att.member_id: att for att in existing_attendance}

    result = []
    
    for enrollment in enrollments:
        member = enrollment.member
        parent_phone = member.parent.phone_number if member.parent else None
        
        # Da li već postoji zapis?
        if member.id in attendance_map:
            att = attendance_map[member.id]
            result.append(schemas.AttendanceOut(
                id=att.id,
                member_id=member.id,
                member_name=member.full_name,
                birth_date=member.date_of_birth,
                is_present=att.is_present,
                date=date_str,
                parent_phone=parent_phone,
                medical_notes=member.notes,
            ))
        else:
            result.append(schemas.AttendanceOut(
                id=0,
                member_id=member.id,
                member_name=member.full_name,
                birth_date=member.date_of_birth,
                is_present=False,
                date=date_str,
                parent_phone=parent_phone,
                medical_notes=member.notes,
            ))

    return result

# 2. Save Batch Attendance
@router.post("/batch", status_code=status.HTTP_200_OK)
async def save_batch_attendance(
    data: schemas.BatchAttendanceCreate,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    if current_user.role not in [models.Role.COACH, models.Role.OWNER]:
        raise HTTPException(status_code=403, detail="Only Coaches/Owners can take attendance")

    # 1. Prvo brišemo stare zapise za taj dan i termin (da ne bi duplirali)
    db.query(models.Attendance).filter(
        models.Attendance.schedule_id == data.schedule_id,
        models.Attendance.date == data.date
    ).delete()
    
    # 2. [FIX] Dohvatamo SVE upisane članove za ovaj termin
    enrollments = db.query(models.Enrollment).filter(
        models.Enrollment.schedule_id == data.schedule_id,
        models.Enrollment.active == True
    ).all()
    
    present_set = set(data.member_ids)  # Set za brzu pretragu
    
    # 3. [FIX] Upisujemo zapis za SVAKOG upisanog člana (Present ili Absent)
    for enrollment in enrollments:
        is_present = enrollment.member_id in present_set
        
        new_record = models.Attendance(
            schedule_id=data.schedule_id,
            member_id=enrollment.member_id,
            date=data.date,
            is_present=is_present,
            coach_id=current_user.id
        )
        db.add(new_record)
    
    db.commit()
    return {"message": "Attendance saved successfully"}


# 3. Get Member Attendance Stats
@router.get("/stats/{member_id}")
async def get_member_stats(
    member_id: int,
    month: int = None,
    year: int = None,
    db: Session = Depends(auth.get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    if current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only Owner can view stats")

    member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")

    query = db.query(models.Attendance).filter(models.Attendance.member_id == member_id)

    if month and year:
        from sqlalchemy import extract
        query = query.filter(
            extract('month', models.Attendance.date) == month,
            extract('year', models.Attendance.date) == year,
        )
    elif year:
        from sqlalchemy import extract
        query = query.filter(extract('year', models.Attendance.date) == year)

    records = query.order_by(models.Attendance.date.desc()).all()

    total = len(records)
    present = sum(1 for r in records if r.is_present)
    percentage = round((present / total) * 100, 1) if total > 0 else 0.0

    history = []
    for r in records:
        history.append({
            "id": r.id,
            "date": r.date.isoformat(),
            "is_present": r.is_present,
        })

    return {
        "total": total,
        "present": present,
        "percentage": percentage,
        "history": history,
    }