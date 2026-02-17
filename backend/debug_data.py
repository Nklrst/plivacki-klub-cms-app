# backend/debug_data.py
import sys
import os

# Dodajemo putanju da vidimo backend fajlove
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.database import SessionLocal
from backend import models

def inspect_database():
    db = SessionLocal()
    print("-" * 50)
    print("🔍 INSPEKCIJA BAZE PODATAKA")
    print("-" * 50)

    # 1. Proveri decu (Members)
    members = db.query(models.Member).all()
    print(f"\n👶 DECA ({len(members)}):")
    for m in members:
        print(f"   - ID: {m.id} | Ime: {m.full_name} | RoditeljID: {m.parent_id}")

    # 2. Proveri termine (Schedules)
    schedules = db.query(models.Schedule).all()
    print(f"\n📅 TERMINI ({len(schedules)}):")
    for s in schedules:
        print(f"   - ID: {s.id} | Grupa: {s.group_name} | Dan: {s.day_of_week} | Vreme: {s.start_time}-{s.end_time}")

    # 3. Proveri upise (Enrollments) - OVO JE KLJUČNO
    enrollments = db.query(models.Enrollment).all()
    print(f"\n📝 UPISI (ENROLLMENTS) ({len(enrollments)}):")
    
    if not enrollments:
        print("   ❌ NEMA UPISA U BAZI! (Roditelj nije uspešno sačuvao ili je baza prazna)")
    
    for e in enrollments:
        # Probamo da dohvatimo imena
        member = db.query(models.Member).filter(models.Member.id == e.member_id).first()
        schedule = db.query(models.Schedule).filter(models.Schedule.id == e.schedule_id).first()
        
        m_name = member.full_name if member else "Nepoznato"
        s_info = f"{schedule.day_of_week} {schedule.start_time}" if schedule else "Nepoznato"

        status_icon = "✅" if e.active else "❌"
        print(f"   {status_icon} Dete: {m_name} (ID={e.member_id}) -> Termin: {s_info} (ID={e.schedule_id}) | Active: {e.active}")

    print("-" * 50)
    db.close()

if __name__ == "__main__":
    inspect_database()