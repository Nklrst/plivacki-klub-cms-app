"""
Seed script for populating payments history (2025 - 2026).
Run with: python -m backend.seed_payments
"""

import random
from datetime import date
from backend.database import SessionLocal, engine, Base
from backend.models import Member, Payment, PaymentMethod # Proveri da li se Enum zove PaymentMethod ili drugacije u models.py

# Podešavanja
YEARS = [2025, 2026]
CURRENT_MONTH = 2 # Februar 2026
AMOUNT = 4500.0

def seed_payments():
    db = SessionLocal()
    print("💰 Generišem istoriju plaćanja...")

    try:
        members = db.query(Member).filter(Member.active == True).all()
        if not members:
            print("⚠️ Nema članova u bazi! Prvo pokreni seed_db.py")
            return

        total_payments = 0

        for year in YEARS:
            # Odredi opseg meseci
            start_month = 1
            end_month = 12 if year < 2026 else CURRENT_MONTH

            for month in range(start_month, end_month + 1):
                print(f"   -> Obrađujem: {month}/{year}...")
                
                for member in members:
                    # 90% šanse da je platio (neki uvek kasne)
                    if random.random() < 0.90:
                        
                        # Proveri da li već postoji uplata (da ne dupliramo ako pokreneš skriptu 2 puta)
                        exists = db.query(Payment).filter(
                            Payment.member_id == member.id,
                            Payment.month == month,
                            Payment.year == year
                        ).first()

                        if exists:
                            continue

                        # Nasumičan dan uplate (između 1. i 15. u mesecu)
                        day = random.randint(1, 15)
                        try:
                            payment_date = date(year, month, day)
                        except ValueError:
                            payment_date = date(year, month, 28) # Fallback za februar

                        # Nasumičan metod
                        method = random.choice([PaymentMethod.CASH, PaymentMethod.BANK_TRANSFER])

                        payment = Payment(
                            member_id=member.id,
                            amount=AMOUNT,
                            currency="RSD",
                            payment_date=payment_date,
                            payment_method=method,
                            month=month,
                            year=year,
                            notes="Automatski generisana uplata"
                        )
                        db.add(payment)
                        total_payments += 1
        
        db.commit()
        print(f"✅ Uspešno generisano {total_payments} uplata!")
        print("📊 Sada tvoj finansijski grafik treba da izgleda bogato!")

    except Exception as e:
        print(f"❌ Greška: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_payments()