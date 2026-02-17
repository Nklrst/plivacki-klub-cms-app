from datetime import time
from backend.database import SessionLocal
from backend.models import Schedule, User, Role

def add_schedules():
    db = SessionLocal()
    
    # Get a coach (Assuming the one we seeded exists)
    coach = db.query(User).filter(User.role == Role.COACH).first()
    coach_id = coach.id if coach else None

    schedules = [
        Schedule(
            day_of_week="UTO", # Tuesday
            start_time=time(19, 0),
            end_time=time(20, 0),
            coach_id=coach_id,
            capacity=10
        ),
        Schedule(
            day_of_week="SRE", # Wednesday
            start_time=time(18, 0),
            end_time=time(19, 0),
            coach_id=coach_id,
            capacity=10
        ),
        Schedule(
            day_of_week="PET", # Friday
            start_time=time(18, 0),
            end_time=time(19, 0),
            coach_id=coach_id,
            capacity=10
        )
    ]
    
    db.add_all(schedules)
    db.commit()
    
    print("Added 3 new schedules.")
    for s in schedules:
        db.refresh(s)
        print(f"ID: {s.id} | Day: {s.day_of_week} | Time: {s.start_time}")

    db.close()

if __name__ == "__main__":
    add_schedules()
