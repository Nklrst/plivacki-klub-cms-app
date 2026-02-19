import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# 1. Određujemo tačnu putanju za LOKALNU bazu (kao do sada)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "cms_app_v2.db")
LOCAL_DB_URL = f"sqlite:///{DB_PATH}"

# 2. KLJUČNI DEO: Ako smo na Renderu, uzeće Postgres. Ako smo na tvom kompjuteru, uzeće lokalni SQLite.
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", LOCAL_DB_URL)

# Sigurnosna ispravka (za svaki slučaj, ako Render prepozna stari format)
if SQLALCHEMY_DATABASE_URL.startswith("postgres://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("postgres://", "postgresql://", 1)

# 3. Argumenti za konekciju (SQLite traži check_same_thread, Postgres ne traži ništa)
connect_args = {}
if SQLALCHEMY_DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args=connect_args
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