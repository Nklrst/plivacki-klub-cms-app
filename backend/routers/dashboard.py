"""
Dashboard router — provides high-level stats and today's schedule overview for the Owner dashboard.
"""

from datetime import date
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

import models, schemas
from database import get_db
from utils import get_current_active_user

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

# ── Day-of-week mapping ────────────────────────────────────────
_DAY_MAP = {
    1: 'PON', 2: 'UTO', 3: 'SRE', 4: 'CET', 5: 'PET', 6: 'SUB', 7: 'NED',
}


@router.get("/stats")
def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user),
):
    """Returns high-level club stats."""
    today = date.today()

    active_members = db.query(func.count(models.Member.id)).filter(
        models.Member.active == True
    ).scalar() or 0

    attendance_today = db.query(func.count(models.Attendance.id)).filter(
        models.Attendance.date == today,
        models.Attendance.is_present == True,
    ).scalar() or 0

    revenue_month = db.query(func.sum(models.Payment.amount)).filter(
        models.Payment.month == today.month,
        models.Payment.year == today.year,
    ).scalar() or 0

    return {
        "active_members": active_members,
        "attendance_today": attendance_today,
        "revenue_month": revenue_month,
    }


@router.get("/today-schedules")
def get_today_schedules(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user),
):
    """Returns today's schedules with enrolled/present counts."""
    today = date.today()
    today_day_code = _DAY_MAP.get(today.isoweekday(), '')

    schedules = db.query(models.Schedule).filter(
        models.Schedule.is_active == True,
        models.Schedule.day_of_week == today_day_code,
    ).all()

    result = []
    for sched in schedules:
        enrolled_count = db.query(func.count(models.Enrollment.id)).filter(
            models.Enrollment.schedule_id == sched.id,
            models.Enrollment.active == True,
        ).scalar() or 0

        present_count = db.query(func.count(models.Attendance.id)).filter(
            models.Attendance.schedule_id == sched.id,
            models.Attendance.date == today,
            models.Attendance.is_present == True,
        ).scalar() or 0

        time_str = ""
        if sched.start_time:
            time_str = sched.start_time.strftime("%H:%M")
            if sched.end_time:
                time_str += f" - {sched.end_time.strftime('%H:%M')}"

        result.append({
            "schedule_id": sched.id,
            "group_name": sched.group_name or f"Termin #{sched.id}",
            "time": time_str,
            "location": sched.location or "",
            "enrolled_count": enrolled_count,
            "present_count": present_count,
        })

    return result
