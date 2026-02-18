import enum
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Date, Time, DateTime, Text, Enum, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

# Enums
class Role(str, enum.Enum):
    OWNER = "OWNER"
    COACH = "COACH"
    PARENT = "PARENT"

class AttendanceStatus(str, enum.Enum):
    PRESENT = "PRESENT"
    ABSENT = "ABSENT"
    EXCUSED = "EXCUSED"

class MessageScope(str, enum.Enum):
    DIRECT = "DIRECT"
    GROUP_SCHEDULE = "GROUP_SCHEDULE"
    BROADCAST_ALL = "BROADCAST_ALL"
    INTERNAL_STAFF = "INTERNAL_STAFF"

class PaymentMethod(str, enum.Enum):
    CASH = "CASH"
    BANK_TRANSFER = "BANK_TRANSFER"

# Models

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    role = Column(Enum(Role), default=Role.PARENT, nullable=False)
    phone_number = Column(String, nullable=True)
    telegram_chat_id = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    members = relationship("Member", back_populates="parent")
    sent_messages = relationship("Message", back_populates="sender", foreign_keys="Message.sender_id")
    received_messages = relationship("Message", back_populates="recipient", foreign_keys="Message.recipient_id")
    coached_schedules = relationship("Schedule", back_populates="coach")
    
    # Progress tracking (User as coach validation)
    validated_skills = relationship("MemberSkill", back_populates="coach")


class Member(Base):
    __tablename__ = "members"

    id = Column(Integer, primary_key=True, index=True)
    parent_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    full_name = Column(String, nullable=False)
    date_of_birth = Column(Date, nullable=False)
    notes = Column(Text, nullable=True)
    active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    parent = relationship("User", back_populates="members")
    enrollments = relationship("Enrollment", back_populates="member")
    attendance_records = relationship("Attendance", back_populates="member")
    acquired_skills = relationship("MemberSkill", back_populates="member")
    payments = relationship("Payment", back_populates="member")


class Schedule(Base):
    __tablename__ = "schedules"

    id = Column(Integer, primary_key=True, index=True)
    day_of_week = Column(String, nullable=False)  # e.g. "PON", "UTO"
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    coach_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    capacity = Column(Integer, default=10)
    group_name = Column(String, nullable=True) # e.g. "Škola plivanja"
    location = Column(String, nullable=True) # e.g. "Bazeni 11. April"
    is_active = Column(Boolean, default=True)

    # Relationships
    coach = relationship("User", back_populates="coached_schedules")
    enrollments = relationship("Enrollment", back_populates="schedule")
    attendance_logs = relationship("Attendance", back_populates="schedule")
    cancellations = relationship("ScheduleCancellation", back_populates="schedule")
    targeted_messages = relationship("Message", back_populates="target_schedule")


class Enrollment(Base):
    __tablename__ = "enrollments"

    id = Column(Integer, primary_key=True, index=True)
    member_id = Column(Integer, ForeignKey("members.id"), nullable=False)
    schedule_id = Column(Integer, ForeignKey("schedules.id"), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=True)
    active = Column(Boolean, default=True)

    # Relationships
    member = relationship("Member", back_populates="enrollments")
    schedule = relationship("Schedule", back_populates="enrollments")


class ScheduleCancellation(Base):
    __tablename__ = "schedule_cancellations"

    id = Column(Integer, primary_key=True, index=True)
    schedule_id = Column(Integer, ForeignKey("schedules.id"), nullable=False)
    cancel_date = Column(Date, nullable=False)
    reason = Column(String, nullable=True)

    # Relationships
    schedule = relationship("Schedule", back_populates="cancellations")


class Attendance(Base):
    __tablename__ = "attendance"

    id = Column(Integer, primary_key=True, index=True)
    schedule_id = Column(Integer, ForeignKey("schedules.id"), nullable=False)
    member_id = Column(Integer, ForeignKey("members.id"), nullable=False)
    coach_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    date = Column(Date, nullable=False)
    is_present = Column(Boolean, default=True)

    # Relationships
    schedule = relationship("Schedule", back_populates="attendance_logs")
    member = relationship("Member", back_populates="attendance_records")
    coach = relationship("User")


class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    image_url = Column(String, nullable=True)
    sent_at = Column(DateTime(timezone=True), server_default=func.now())
    scope = Column(Enum(MessageScope), nullable=False)
    
    target_schedule_id = Column(Integer, ForeignKey("schedules.id"), nullable=True)
    recipient_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    # Relationships
    sender = relationship("User", back_populates="sent_messages", foreign_keys=[sender_id])
    recipient = relationship("User", back_populates="received_messages", foreign_keys=[recipient_id])
    target_schedule = relationship("Schedule", back_populates="targeted_messages")


class Skill(Base):
    __tablename__ = "skills"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True, nullable=False)
    description = Column(String, nullable=True)
    category_label = Column(String, nullable=True) # Etapni cilj
    display_order = Column(Integer, default=0)

    # Relationships
    member_achievements = relationship("MemberSkill", back_populates="skill")


class MemberSkill(Base):
    __tablename__ = "member_skills"

    id = Column(Integer, primary_key=True, index=True)
    member_id = Column(Integer, ForeignKey("members.id"), nullable=False)
    skill_id = Column(Integer, ForeignKey("skills.id"), nullable=False)
    acquired_at = Column(Date, nullable=False)
    coach_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    # Relationships
    member = relationship("Member", back_populates="acquired_skills")
    skill = relationship("Skill", back_populates="member_achievements")
    coach = relationship("User", back_populates="validated_skills")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    member_id = Column(Integer, ForeignKey("members.id"), nullable=False)
    amount = Column(Float, nullable=False)
    currency = Column(String, default="RSD")
    payment_date = Column(Date, nullable=False)
    payment_method = Column(Enum(PaymentMethod), nullable=False)
    month = Column(Integer, nullable=False)   # 1-12
    year = Column(Integer, nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    member = relationship("Member", back_populates="payments")
