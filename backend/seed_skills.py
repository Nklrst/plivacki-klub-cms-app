from backend.database import SessionLocal
from backend.models import Skill

def seed_skills():
    db = SessionLocal()
    try:
        # Check if skills exist
        if db.query(Skill).count() > 0:
            print("Skills table already populated. Skipping seed.")
            return

        print("Seeding skills...")
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
        print("Successfully seeded 14 skills.")
    except Exception as e:
        print(f"Error seeding skills: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_skills()
