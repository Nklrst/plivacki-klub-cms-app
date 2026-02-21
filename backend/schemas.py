from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import date
from models import Role, MessageScope

# --- Token Schemas ---
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None
    role: Optional[Role] = None

# --- Member Schemas ---
class MemberBase(BaseModel):
    full_name: str
    date_of_birth: date
    notes: Optional[str] = None

class MemberCreate(MemberBase):
    pass

class MemberOut(MemberBase):
    id: int
    active: bool
    enrollments: List['EnrollmentOut'] = [] # Forward reference as string to avoid circular
    
    class Config:
        from_attributes = True

# --- User Schemas ---
class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    phone_number: Optional[str] = None

class UserCreate(UserBase):
    password: str
    role: Role = Role.PARENT

class UserOut(UserBase):
    id: int
    role: Role
    is_active: bool
    members: List[MemberOut] = []

    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class PasswordChange(BaseModel):
    old_password: str
    new_password: str

# --- Schedule Schemas ---
from datetime import time

class ScheduleBase(BaseModel):
    day_of_week: str
    start_time: time
    end_time: time
    capacity: int
    group_name: Optional[str] = None
    location: Optional[str] = None

class ScheduleCreate(ScheduleBase):
    pass

class ScheduleOut(ScheduleBase):
    id: int
    coach_id: Optional[int]
    is_active: bool
    current_enrollments_count: int = 0
    
    class Config:
        from_attributes = True

# --- Enrollment Schemas ---
class EnrollmentCreate(BaseModel):
    member_id: int
    schedule_id: int
    start_date: date

class EnrollmentOut(BaseModel):
    id: int
    member_id: int
    schedule_id: int
    active: bool
    schedule: ScheduleOut # Include nested schedule info
    
    class Config:
        from_attributes = True

# --- Message Schemas ---
from datetime import datetime

class MessageCreate(BaseModel):
    content: str
    scope: MessageScope
    recipient_id: Optional[int] = None
    target_schedule_id: Optional[int] = None
    image_url: Optional[str] = None

class MessageOut(BaseModel):
    id: int
    sender_id: int
    content: str
    scope: MessageScope
    sent_at: datetime
    image_url: Optional[str] = None
    recipient_id: Optional[int] = None
    target_schedule_id: Optional[int] = None
    sender_name: str = "" # Enriched field

    class Config:
        from_attributes = True

# --- Skill Schemas ---
class SkillBase(BaseModel):
    name: str
    description: Optional[str] = None
    category_label: Optional[str] = None
    display_order: int

class SkillCreate(SkillBase):
    pass

class SkillOut(SkillBase):
    id: int
    
    class Config:
        from_attributes = True

class MemberSkillBase(BaseModel):
    skill_id: int

class MemberSkillOut(BaseModel):
    id: int
    skill: SkillOut
    acquired_at: date
    coach_id: Optional[int]
    
    class Config:
        from_attributes = True

class MemberSkillStatus(BaseModel):
    """Flat view of a skill with mastered flag — used by Coach dialog"""
    skill_id: int
    skill_name: str
    is_mastered: bool

class MemberSkillBatchUpdate(BaseModel):
    """Accepts list of mastered skill IDs from the Coach dialog"""
    mastered_skill_ids: List[int]

# --- ATTENDANCE SCHEMAS (Dodato ručno) ---

class AttendanceCreate(BaseModel):
    schedule_id: int
    member_id: int
    date: date
    is_present: bool = True

class AttendanceOut(BaseModel):
    id: int
    member_id: int
    member_name: str
    birth_date: date | None = None
    is_present: bool
    date: date
    parent_phone: str | None = None
    medical_notes: str | None = None

    class Config:
        from_attributes = True

class BatchAttendanceCreate(BaseModel):
    schedule_id: int
    date: date
    member_ids: List[int]

# --- Payment Schemas ---
from models import PaymentMethod

class PaymentCreate(BaseModel):
    member_id: int
    amount: float
    payment_date: date
    payment_method: PaymentMethod
    month: int
    year: int
    notes: Optional[str] = None

class PaymentOut(BaseModel):
    id: int
    member_id: int
    amount: float
    currency: str
    payment_date: date
    payment_method: PaymentMethod
    month: int
    year: int
    notes: Optional[str] = None
    member_name: str = ""

    class Config:
        from_attributes = True
