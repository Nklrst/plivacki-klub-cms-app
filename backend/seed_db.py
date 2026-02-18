"""
Seed script for populating the database with realistic test data.
Run with: python -m backend.seed_db
"""

import random
import os
from datetime import date, timedelta
from backend.database import SessionLocal, engine, Base
from backend.models import (
    User, Member, Schedule, Enrollment, Attendance, Skill, MemberSkill, Role
)
from utils import get_password_hash


# ── Config ──────────────────────────────────────────────────────
PARENT_PASSWORD = "parent123"

PARENT_DATA = [
    {"full_name": "Jelena Petrović", "email": "jelena@test.com", "phone": "0641234567"},
    {"full_name": "Dragan Nikolić",  "email": "dragan@test.com", "phone": "0652345678"},
    {"full_name": "Milica Jovanović", "email": "milica@test.com", "phone": "0663456789"},
]

CHILD_NAMES = [
    "Marko", "Jovana", "Luka", "Sara", "Stefan",
    "Ana", "Nikola", "Milica", "Filip", "Teodora",
]

ATTENDANCE_DAYS = 30      # Generate history for past N days
PRESENT_CHANCE = 0.80     # 80% chance to be present
SKILLS_PER_CHILD = (3, 5) # Random range of mastered skills


def seed():
    # Kreiramo tabele ako ne postoje
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    print(f"📂 Baza podataka: {engine.url}")

    try:
        hashed_pw = get_password_hash(PARENT_PASSWORD)

        # ── 1. Create or Get Parents ───────────────────────────────────
        parents = []
        print("👤 Proveravam roditelje...")
        
        for p in PARENT_DATA:
            # Proveri da li postoji
            user = db.query(User).filter(User.email == p["email"]).first()
            
            if user:
                print(f"   -> Roditelj {p['full_name']} već postoji. Koristim postojećeg.")
            else:
                print(f"   -> Kreiram novog roditelja: {p['full_name']}")
                user = User(
                    email=p["email"],
                    hashed_password=hashed_pw,
                    full_name=p["full_name"],
                    role=Role.PARENT,
                    phone_number=p["phone"],
                    is_active=True,
                )
                db.add(user)
                db.commit() # Odmah čuvamo da bismo imali ID
                db.refresh(user)
            
            parents.append(user)

        print(f"✅ Ukupno roditelja za povezivanje: {len(parents)}")

        # ── 2. Check Schedules ──────────────────────────────────────────
        schedules = db.query(Schedule).filter(Schedule.is_active == True).all()
        if not schedules:
            print("\n⚠️  NEMA AKTIVNIH TERMINA (SCHEDULES) U BAZI!")
            print("👉 Molim te uloguj se kao Vlasnik (Owner) i napravi bar jedan termin pre pokretanja skripte.")
            return

        print(f"📅 Pronađeno {len(schedules)} termina za upis.")

        # ── 3. Create Children (Members) ────────────────────────
        print("\n👶 Kreiram decu...")
        members = []
        for name in CHILD_NAMES:
            parent = random.choice(parents)
            age = random.randint(5, 12)
            dob = date.today() - timedelta(days=age * 365 + random.randint(0, 364))

            child_name = f"{name} {parent.full_name.split()[-1]}"
            existing_child = db.query(Member).filter(Member.full_name == child_name).first()
            
            if existing_child:
                member = existing_child
            else:
                member = Member(
                    parent_id=parent.id,
                    full_name=child_name,
                    date_of_birth=dob,
                    notes=f"Test podatak, uzrast {age} god.",
                    active=True,
                )
                db.add(member)
                db.commit()
                db.refresh(member)
            
            members.append(member)

        print(f"✅ Ukupno dece: {len(members)}")

        # ── 4. Create Enrollments ───────────────────────────────
        print("\n📝 Upisujem decu na termine...")
        enrollment_count = 0
        
        for member in members:
            # Svako dete na 1 do 2 termina
            n = random.randint(1, min(2, len(schedules)))
            chosen = random.sample(schedules, n)
            
            for sched in chosen:
                exists = db.query(Enrollment).filter(
                    Enrollment.member_id == member.id,
                    Enrollment.schedule_id == sched.id
                ).first()

                if not exists:
                    enrollment = Enrollment(
                        member_id=member.id,
                        schedule_id=sched.id,
                        start_date=date.today() - timedelta(days=60),
                        active=True,
                    )
                    db.add(enrollment)
                    enrollment_count += 1
        
        db.commit()
        print(f"✅ Kreirano {enrollment_count} novih upisa.")

        # ── 5. Generate Attendance History ──────────────────────
        print("\n⏱️  Generišem prisustva...")
        coach = db.query(User).filter(User.role == Role.COACH).first()
        coach_id = coach.id if coach else 1 

        att_count = 0
        all_enrollments = db.query(Enrollment).filter(Enrollment.active == True).all()

        for enr in all_enrollments:
            # [POPRAVLJENO] Legacy warning - koristimo db.get() umesto db.query().get()
            sched = db.get(Schedule, enr.schedule_id)
            if not sched: continue

            target_weekday = _parse_weekday(sched.day_of_week)
            if target_weekday is None: continue

            for day_offset in range(ATTENDANCE_DAYS):
                record_date = date.today() - timedelta(days=day_offset)
                
                if record_date.isoweekday() == target_weekday:
                    exists = db.query(Attendance).filter(
                        Attendance.schedule_id == sched.id,
                        Attendance.member_id == enr.member_id,
                        Attendance.date == record_date
                    ).first()

                    if not exists:
                        is_present = random.random() < PRESENT_CHANCE
                        att = Attendance(
                            schedule_id=sched.id,
                            member_id=enr.member_id,
                            coach_id=coach_id,
                            date=record_date,
                            is_present=is_present,
                        )
                        db.add(att)
                        att_count += 1

        db.commit()
        print(f"✅ Generisano {att_count} zapisa o prisustvu.")

        # ── 6. Assign Random Skills ─────────────────────────────
        print("\n🏊 Dodeljujem veštine...")
        all_skills = db.query(Skill).all()
        
        if all_skills:
            skill_count = 0
            for member in members:
                n = random.randint(*SKILLS_PER_CHILD)
                chosen_skills = random.sample(all_skills, min(n, len(all_skills)))
                
                for skill in chosen_skills:
                    exists = db.query(MemberSkill).filter(
                        MemberSkill.member_id == member.id,
                        MemberSkill.skill_id == skill.id
                    ).first()
                    
                    if not exists:
                        ms = MemberSkill(
                            member_id=member.id,
                            skill_id=skill.id,
                            acquired_at=date.today() - timedelta(days=random.randint(1, 90)),
                            coach_id=coach_id,
                            # [POPRAVLJENO] Sklonili smo 'is_mastered=True' jer ne postoji u modelu
                        )
                        db.add(ms)
                        skill_count += 1
            db.commit()
            print(f"✅ Dodeljeno {skill_count} novih veština.")
        else:
            print("⚠️ Nema veština u bazi (pokreni aplikaciju jednom da se kreiraju).")

        print("\n🎉 GOTOVO! Baza je napunjena.")

    except Exception as e:
        db.rollback()
        print(f"❌ GREŠKA: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()


# ── Helper ──────────────────────────────────────────────────────
_DAY_MAP = {
    'PON': 1, 'PONEDELJAK': 1, 'MONDAY': 1, 'MON': 1,
    'UTO': 2, 'UTORAK': 2, 'TUESDAY': 2, 'TUE': 2,
    'SRE': 3, 'SREDA': 3, 'WEDNESDAY': 3, 'WED': 3,
    'CET': 4, 'CETVRTAK': 4, 'THURSDAY': 4, 'THU': 4,
    'PET': 5, 'PETAK': 5, 'FRIDAY': 5, 'FRI': 5,
    'SUB': 6, 'SUBOTA': 6, 'SATURDAY': 6, 'SAT': 6,
    'NED': 7, 'NEDELJA': 7, 'SUNDAY': 7, 'SUN': 7,
}

def _parse_weekday(day_str: str) -> int | None:
    if not day_str: return None
    return _DAY_MAP.get(day_str.upper().strip())


if __name__ == "__main__":
    seed()