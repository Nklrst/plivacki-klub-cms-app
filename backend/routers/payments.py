from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func as sa_func
from typing import List
from datetime import date
import models, schemas, auth, database

router = APIRouter(
    prefix="/payments",
    tags=["Payments"],
)


# --- A. Yearly Summary (Revenue per month) ---
@router.get("/yearly-summary")
def yearly_summary(
    year: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    if current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only Owner can view")

    rows = (
        db.query(
            models.Payment.month,
            sa_func.sum(models.Payment.amount).label("total_revenue"),
            sa_func.count(models.Payment.id).label("payment_count"),
        )
        .filter(models.Payment.year == year)
        .group_by(models.Payment.month)
        .all()
    )

    lookup = {r.month: {"total_revenue": r.total_revenue or 0, "payment_count": r.payment_count} for r in rows}

    result = []
    for m in range(1, 13):
        data = lookup.get(m, {"total_revenue": 0, "payment_count": 0})
        result.append({"month": m, **data})

    return result


# --- B. Debtors (Members who haven't paid for a month) ---
@router.get("/debtors")
def debtors(
    month: int,
    year: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    if current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only Owner can view")

    active_members = db.query(models.Member).filter(models.Member.active == True).all()

    paid_member_ids = set(
        r[0]
        for r in db.query(models.Payment.member_id)
        .filter(models.Payment.month == month, models.Payment.year == year)
        .all()
    )

    result = []
    for m in active_members:
        if m.id not in paid_member_ids:
            result.append({
                "id": m.id,
                "full_name": m.full_name,
                "parent_name": m.parent.full_name if m.parent else None,
                "parent_phone": m.parent.phone_number if m.parent else None,
            })

    return result


# --- C. Create Payment ---
@router.post("/", response_model=schemas.PaymentOut, status_code=status.HTTP_201_CREATED)
def create_payment(
    payment: schemas.PaymentCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    if current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only Owner can record payments")

    member = db.query(models.Member).filter(models.Member.id == payment.member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")

    db_payment = models.Payment(
        member_id=payment.member_id,
        amount=payment.amount,
        payment_date=payment.payment_date,
        payment_method=payment.payment_method,
        month=payment.month,
        year=payment.year,
        notes=payment.notes,
    )
    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)

    return schemas.PaymentOut(
        id=db_payment.id,
        member_id=db_payment.member_id,
        amount=db_payment.amount,
        currency=db_payment.currency,
        payment_date=db_payment.payment_date,
        payment_method=db_payment.payment_method,
        month=db_payment.month,
        year=db_payment.year,
        notes=db_payment.notes,
        member_name=member.full_name,
    )


# --- D. Payment History (Latest 50) ---
@router.get("/history", response_model=List[schemas.PaymentOut])
def payment_history(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    if current_user.role != models.Role.OWNER:
        raise HTTPException(status_code=403, detail="Only Owner can view")

    payments = (
        db.query(models.Payment)
        .order_by(models.Payment.created_at.desc())
        .limit(50)
        .all()
    )

    result = []
    for p in payments:
        result.append(schemas.PaymentOut(
            id=p.id,
            member_id=p.member_id,
            amount=p.amount,
            currency=p.currency,
            payment_date=p.payment_date,
            payment_method=p.payment_method,
            month=p.month,
            year=p.year,
            notes=p.notes,
            member_name=p.member.full_name if p.member else "",
        ))

    return result


# --- E. Payment Status (For Parents) ---
@router.get("/status/{member_id}")
def get_payment_status(
    member_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    # Allow Owner or the Parent of the member
    member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")

    if current_user.role != models.Role.OWNER:
        if member.parent_id != current_user.id:
             raise HTTPException(status_code=403, detail="Not authorized")

    today = date.today()
    # Serbian month names (0-index placeholder)
    month_names = ["", "Januar", "Februar", "Mart", "April", "Maj", "Jun", 
                   "Jul", "Avgust", "Septembar", "Oktobar", "Novembar", "Decembar"]
    
    payment = db.query(models.Payment).filter(
        models.Payment.member_id == member_id,
        models.Payment.month == today.month,
        models.Payment.year == today.year
    ).first()

    return {
        "is_paid": payment is not None,
        "month_name": month_names[today.month]
    }
