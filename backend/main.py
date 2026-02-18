from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
# [FIX] Dodao sam 'attendance' u listu importa
from routers import auth, users, schedules, messages, skills, members, attendance, dashboard, payments


# Create tables on startup
Base.metadata.create_all(bind=engine)

# Auto-seed skills if empty
from seed_skills import seed_skills
seed_skills()

app = FastAPI(title="PK Ušće CMS")

# CORS Middleware (Dozvoljava pristup sa svih adresa)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(members.router)
app.include_router(schedules.router)
app.include_router(messages.router)
app.include_router(skills.router)
# [FIX] Ovo sada radi jer smo ga importovali gore
app.include_router(attendance.router)
app.include_router(dashboard.router)
app.include_router(payments.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to PK Ušće Club Management System API"}