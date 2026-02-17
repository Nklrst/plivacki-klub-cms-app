import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# 1. Određujemo tačnu putanju do ovog fajla (database.py)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# 2. Spajamo putanju foldera sa imenom baze
# Ovo garantuje da Python uvek gađa pravi fajl, odakle god da pokreneš server
DB_PATH = os.path.join(BASE_DIR, "cms_app_v2.db")

SQLALCHEMY_DATABASE_URL = f"sqlite:///{DB_PATH}"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Funkcija za dependency injection
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()