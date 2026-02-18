from backend.database import SessionLocal, engine, Base
from backend.database import SessionLocal, engine, Base
from backend.models import User, Member, Schedule, Role, Enrollment, Message, Skill
from utils import get_password_hash # Import hashing function
import os

from datetime import date, time

def init_db():
    # 0. Clean run - Drop all tables
    Base.metadata.drop_all(bind=engine)
    print("Dropped all tables.")

    # Create tables
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    # 1. Create Users
    # Using real bcrypt hashing now
    owner = User(
        email="owner@example.com",
        hashed_password=get_password_hash("admin123"), 
        full_name="Club Owner",
        role=Role.OWNER
    )
    
    coach = User(
        email="coach@example.com",
        hashed_password=get_password_hash("coach123"),
        full_name="Head Coach",
        role=Role.COACH
    )
    
    parent = User(
        email="parent@example.com",
        hashed_password=get_password_hash("parent123"),
        full_name="John Doe",
        role=Role.PARENT
    )
    
    db.add_all([owner, coach, parent])
    db.commit()
    db.refresh(parent)
    db.refresh(coach)

    # 2. Create Members (Children)
    child1 = Member(
        parent_id=parent.id,
        full_name="Alice Doe",
        date_of_birth=date(2015, 5, 20),
        notes="Peanut allergy"
    )
    
    child2 = Member(
        parent_id=parent.id,
        full_name="Bob Doe",
        date_of_birth=date(2017, 8, 15)
    )
    
    db.add_all([child1, child2])
    db.commit()

    # 3. Create Schedule
    # Mon 18:00 - 19:00
    schedule = Schedule(
        day_of_week="PON", # Monday
        start_time=time(18, 0),
        end_time=time(19, 0),
        coach_id=coach.id,
        capacity=10
    )
    
    db.add(schedule)
    db.commit()

    # 4. Create Skills (14 items)
    # 4. Create Skills (14 items)
    skills_data = [
        # Etapni cilj 1
        {"name": "Disanje", "category": "Etapni cilj 1", "order": 1},
        {"name": "Plutanje", "category": "Etapni cilj 1", "order": 2},
        {"name": "Skok u vodu na noge", "category": "Etapni cilj 1", "order": 3},
        {"name": "Ronjenje (podizanje predmeta sa dubine od 1.5m)", "category": "Etapni cilj 1", "order": 4},
        {"name": "Kolut unapred u vodi", "category": "Etapni cilj 1", "order": 5},
        {"name": "Klizanja na stomaku i leđima (u streamline-u)", "category": "Etapni cilj 1", "order": 6},
        {"name": "Rad nogama kraul (sa/bez daske) i leđno", "category": "Etapni cilj 1", "order": 7},

        # Etapni cilj 2
        {"name": "Rad nogama kraul u svim položajima i disanje", "category": "Etapni cilj 2", "order": 8},
        {"name": "Ceo stil kraul i leđno", "category": "Etapni cilj 2", "order": 9},
        {"name": "Rad nogama prsno", "category": "Etapni cilj 2", "order": 10},

        # Etapni cilj 3
        {"name": "Usavršavanje kraul i leđnog stila", "category": "Etapni cilj 3", "order": 11},
        {"name": "Obuka prsnog i delfin stila", "category": "Etapni cilj 3", "order": 12},
        {"name": "Obuka mešovitog (okreti, podvodni)", "category": "Etapni cilj 3", "order": 13},
        {"name": "Skok na glavu", "category": "Etapni cilj 3", "order": 14},
    ]

    for s in skills_data:
        skill = Skill(
            name=s["name"],
            category_label=s["category"],
            display_order=s["order"]
        )
        db.add(skill)
    
    db.commit()
    print("Seeded 14 Skills.")
    
    print("Database initialized and seeded successfully!")
    db.close()

if __name__ == "__main__":
    init_db()
