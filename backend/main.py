from fastapi import FastAPI, HTTPException, Depends, File, UploadFile, Form, Request, Query, Body
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, Text, Float, ForeignKey, Table, case, Enum as SqlEnum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
from sqlalchemy.dialects.sqlite import JSON
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
import jwt
import os
import base64
import uuid
import requests
from pathlib import Path
from fastapi.staticfiles import StaticFiles
import httpx
import random
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.types import JSON as SQLAlchemyJSON
import asyncio
import threading

# Custom datetime function with 5 hours 30 minutes delay
def get_delayed_datetime():
    """Returns current datetime with 5 hours 30 minutes delay"""
    return datetime.utcnow() + timedelta(hours=5, minutes=30)

# PhonePe SDK imports
from phonepe.sdk.pg.payments.v2.standard_checkout_client import StandardCheckoutClient
from phonepe.sdk.pg.payments.v2.models.request.standard_checkout_pay_request import StandardCheckoutPayRequest
from phonepe.sdk.pg.common.models.request.meta_info import MetaInfo
from phonepe.sdk.pg.env import Env

# PhonePe Configuration
CLIENT_ID = "SU2507081541044452831844"
CLIENT_SECRET = "dfb3d18b-6cba-4fcc-8d05-6ef5c3f0c9a8"
CLIENT_VERSION = 1
ENV = Env.PRODUCTION

# Initialize PhonePe client (singleton)
phonepe_client = StandardCheckoutClient.get_instance(
    client_id=CLIENT_ID,
    client_secret=CLIENT_SECRET,
    client_version=CLIENT_VERSION,
    env=ENV,
    should_publish_events=False
)

# Database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./social_app.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Create directories for file uploads
os.makedirs("uploads/music", exist_ok=True)
os.makedirs("uploads/thumbnails", exist_ok=True)
os.makedirs("uploads/backgrounds", exist_ok=True)
os.makedirs("uploads/gifts", exist_ok=True)
os.makedirs("uploads/profile_pics", exist_ok=True)

# Association tables for many-to-many relationships
user_interests = Table('user_interests', Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id')),
    Column('interest', String)
)

user_blocked = Table('user_blocked', Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id')),
    Column('blocked_user_id', Integer, ForeignKey('users.id'))
)

user_following = Table('user_following', Base.metadata,
    Column('follower_id', Integer, ForeignKey('users.id')),
    Column('following_id', Integer, ForeignKey('users.id'))
)

# Database Models
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String, nullable=True)
    last_name = Column(String, nullable=True)
    username = Column(String, unique=True, nullable=True)
    phone_number = Column(String, unique=True, index=True)
    email = Column(String, nullable=True)
    profile_pic = Column(Text, nullable=True)  # Base64
    dob = Column(DateTime, nullable=True)
    gender = Column(String, nullable=True)
    bio = Column(Text, nullable=True)
    instagram_user_id = Column(String, nullable=True)
    language = Column(String, nullable=True)
    balance = Column(Float, default=0.0)
    diamonds = Column(Integer, default=0)
    upi_id = Column(String, nullable=True)
    bank_account_name = Column(String, nullable=True)
    bank_account_number = Column(String, nullable=True)
    bank_ifsc = Column(String, nullable=True)
    is_online = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=get_delayed_datetime)
    
    # Relationships
    diamond_history = relationship("DiamondHistory", back_populates="user")
    audio_lives = relationship("GoLiveAudio", back_populates="user")
    video_lives = relationship("GoLiveVideo", back_populates="user")
    sent_messages = relationship("Message", foreign_keys="Message.sender_id", back_populates="sender")
    received_messages = relationship("Message", foreign_keys="Message.receiver_id", back_populates="receiver")

class DiamondHistory(Base):
    __tablename__ = "diamond_history"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    datetime = Column(DateTime, default=get_delayed_datetime)
    amount = Column(Integer)
    status = Column(String)  # credited, debit, bought
    
    user = relationship("User", back_populates="diamond_history")

class Slider(Base):
    __tablename__ = "sliders"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    img = Column(Text)  # Base64
    created_at = Column(DateTime, default=get_delayed_datetime)

class LoginScreen(Base):
    __tablename__ = "login_screens"
    
    id = Column(Integer, primary_key=True, index=True)
    gif = Column(Text)  # Base64
    created_at = Column(DateTime, default=get_delayed_datetime)

class GoLiveAudio(Base):
    __tablename__ = "go_live_audio"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String)
    chat_room = Column(String)
    hashtag = Column(JSON)  # Multiple hashtags
    music_id = Column(Integer, ForeignKey("music.id"), nullable=True)
    background_img = Column(String, nullable=True)
    live_url = Column(String)
    language = Column(String, nullable=True)  # Added field
    created_at = Column(DateTime, default=get_delayed_datetime)
    
    user = relationship("User", back_populates="audio_lives")
    music = relationship("Music")

class GoLiveVideo(Base):
    __tablename__ = "go_live_video"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    category = Column(String)
    hashtag = Column(JSON)  # Multiple hashtags
    live_url = Column(String)
    language = Column(String, nullable=True)  # Added field
    created_at = Column(DateTime, default=get_delayed_datetime)
    
    user = relationship("User", back_populates="video_lives")

class Music(Base):
    __tablename__ = "music"
    
    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String)
    thumbnail_filename = Column(String, nullable=True)
    created_at = Column(DateTime, default=get_delayed_datetime)

class BackgroundImage(Base):
    __tablename__ = "background_images"
    
    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String)
    created_at = Column(DateTime, default=get_delayed_datetime)

class Gift(Base):
    __tablename__ = "gifts"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    gif_filename = Column(String)
    diamond_amount = Column(Integer)
    created_at = Column(DateTime, default=get_delayed_datetime)

class GiftTransaction(Base):
    __tablename__ = "gift_transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"))
    receiver_id = Column(Integer, ForeignKey("users.id"))
    gift_id = Column(Integer, ForeignKey("gifts.id"))
    diamond_amount = Column(Integer)
    live_stream_id = Column(Integer, nullable=True)  # ID of the live stream where gift was sent
    live_stream_type = Column(String, nullable=True)  # 'audio' or 'video'
    created_at = Column(DateTime, default=get_delayed_datetime)
    
    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])
    gift = relationship("Gift")

class PaymentTransaction(Base):
    __tablename__ = "payment_transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    merchant_order_id = Column(String, unique=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    gift_id = Column(Integer, ForeignKey("gifts.id"))
    gift_name = Column(String)
    diamond_amount = Column(Integer)
    amount_paid = Column(Integer)  # in paise
    status = Column(String, default="PENDING")  # PENDING, SUCCESS, FAILED
    phonepe_transaction_id = Column(String, nullable=True)
    redirect_url = Column(Text, nullable=True)
    payment_method = Column(String, default="PHONEPE")
    currency = Column(String, default="INR")
    created_at = Column(DateTime, default=get_delayed_datetime)
    updated_at = Column(DateTime, default=get_delayed_datetime)
    
    user = relationship("User")
    gift = relationship("Gift")

class UserWallet(Base):
    __tablename__ = "user_wallets"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    balance = Column(Float, default=0.0)
    diamonds = Column(Integer, default=0)
    total_spent = Column(Float, default=0.0)
    total_earned = Column(Float, default=0.0)
    last_updated = Column(DateTime, default=get_delayed_datetime)
    
    user = relationship("User")

class PaymentAnalytics(Base):
    __tablename__ = "payment_analytics"
    
    id = Column(Integer, primary_key=True, index=True)
    date = Column(DateTime, default=get_delayed_datetime)
    total_transactions = Column(Integer, default=0)
    successful_transactions = Column(Integer, default=0)
    failed_transactions = Column(Integer, default=0)
    total_amount = Column(Float, default=0.0)
    total_diamonds_sold = Column(Integer, default=0)
    payment_method = Column(String, default="PHONEPE")
    
    created_at = Column(DateTime, default=get_delayed_datetime)

class Shop(Base):
    __tablename__ = "shops"
    
    id = Column(Integer, primary_key=True, index=True)
    diamond_count = Column(Integer)
    total_price = Column(Float)
    discounted_price = Column(Float)
    created_at = Column(DateTime, default=get_delayed_datetime)

class Message(Base):
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"))
    receiver_id = Column(Integer, ForeignKey("users.id"))
    message = Column(Text)
    timestamp = Column(DateTime, default=get_delayed_datetime)
    is_read = Column(Boolean, default=False)
    
    sender = relationship("User", foreign_keys=[sender_id], back_populates="sent_messages")
    receiver = relationship("User", foreign_keys=[receiver_id], back_populates="received_messages")

# --- ZEGOCLOUD CALLBACK MODELS ---
class Stream(Base):
    __tablename__ = "streams"
    id = Column(Integer, primary_key=True, index=True)
    stream_id = Column(String, unique=True, index=True)
    user_id = Column(Integer, nullable=True)
    started_at = Column(DateTime, default=get_delayed_datetime)
    ended_at = Column(DateTime, nullable=True)
    status = Column(String, default="active")

class Room(Base):
    __tablename__ = "rooms"
    id = Column(Integer, primary_key=True, index=True)
    room_id = Column(String, unique=True, index=True)
    created_at = Column(DateTime, default=get_delayed_datetime)
    status = Column(String, default="active")

class Recording(Base):
    __tablename__ = "recordings"
    id = Column(Integer, primary_key=True, index=True)
    stream_id = Column(String, index=True)
    url = Column(Text)
    obtained_at = Column(DateTime, default=get_delayed_datetime)

class ModerationEvent(Base):
    __tablename__ = "moderation_events"
    id = Column(Integer, primary_key=True, index=True)
    event_type = Column(String)  # 'video' or 'audio'
    stream_id = Column(String, index=True)
    details = Column(Text)
    created_at = Column(DateTime, default=get_delayed_datetime)

class UserType(Base):
    __tablename__ = "user_types"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(String, nullable=False)
    para1 = Column(String, nullable=True)
    para2 = Column(String, nullable=True)
    para3 = Column(String, nullable=True)
    user = relationship("User")

class UserTypeCreate(BaseModel):
    user_id: int
    type: str
    para1: Optional[str] = None
    para2: Optional[str] = None
    para3: Optional[str] = None

class UserTypeUpdate(BaseModel):
    type: Optional[str] = None
    para1: Optional[str] = None
    para2: Optional[str] = None
    para3: Optional[str] = None

class LiveApproval(Base):
    __tablename__ = "live_approval"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    moj_handle = Column(String, nullable=False)
    gender = Column(String, nullable=True)
    dob_day = Column(Integer, nullable=True)
    dob_month = Column(Integer, nullable=True)
    dob_year = Column(Integer, nullable=True)
    genres = Column(SQLAlchemyJSON, nullable=True)
    accepted_terms_of_use = Column(Boolean, default=False)
    accepted_agency_agreement = Column(Boolean, default=False)
    user = relationship("User")

class DateOfBirth(BaseModel):
    day: int
    month: int
    year: int

class LiveApprovalCreate(BaseModel):
    user_id: int
    name: str
    moj_handle: str
    gender: str
    date_of_birth: DateOfBirth
    genres: list[str]
    accepted_terms_of_use: bool
    accepted_agency_agreement: bool

class LiveApprovalUpdate(BaseModel):
    name: Optional[str] = None
    moj_handle: Optional[str] = None
    gender: Optional[str] = None
    date_of_birth: Optional[DateOfBirth] = None
    genres: Optional[list[str]] = None
    accepted_terms_of_use: Optional[bool] = None
    accepted_agency_agreement: Optional[bool] = None

class LiveApprovalResponse(BaseModel):
    id: int
    user_id: int
    name: str
    moj_handle: str
    gender: Optional[str]
    date_of_birth: DateOfBirth
    genres: list[str]
    accepted_terms_of_use: bool
    accepted_agency_agreement: bool

class SingleURL(Base):
    __tablename__ = "single_url"
    id = Column(Integer, primary_key=True, index=True)
    url = Column(String, nullable=False)
    created_at = Column(DateTime, default=get_delayed_datetime)

class SingleURLResponse(BaseModel):
    url: str
    created_at: datetime

class SingleURLUpdate(BaseModel):
    url: str

class HelpSupport(Base):
    __tablename__ = "help_support"
    id = Column(Integer, primary_key=True, index=True)
    content = Column(String, nullable=False)
    created_at = Column(DateTime, default=get_delayed_datetime)

class HelpSupportCreate(BaseModel):
    content: str

class HelpSupportUpdate(BaseModel):
    content: str

class HelpSupportResponse(BaseModel):
    id: int
    content: str
    created_at: datetime

class WithdrawDiamond(Base):
    __tablename__ = "withdraw_diamond"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    diamond_count = Column(Integer, nullable=False)
    status = Column(String, default="Pending")  # Filled, Pending, Approved
    created_at = Column(DateTime, default=get_delayed_datetime)
    user = relationship("User")

class WithdrawDiamondCreate(BaseModel):
    user_id: int
    diamond_count: int
    status: Optional[str] = "Pending"

class WithdrawDiamondUpdate(BaseModel):
    diamond_count: Optional[int] = None
    status: Optional[str] = None

class WithdrawDiamondResponse(BaseModel):
    id: int
    user_id: int
    diamond_count: int
    status: str
    created_at: datetime

class WithdrawDiamondInfo(Base):
    __tablename__ = "withdraw_diamond_info"
    id = Column(Integer, primary_key=True, index=True)
    minimum_diamond = Column(Integer, nullable=False)
    conversion_rate = Column(Float, nullable=False)
    created_at = Column(DateTime, default=get_delayed_datetime)

class WithdrawDiamondInfoUpdate(BaseModel):
    minimum_diamond: Optional[int] = None
    conversion_rate: Optional[float] = None

class WithdrawDiamondInfoResponse(BaseModel):
    minimum_diamond: int
    conversion_rate: float
    created_at: datetime

class Star(Base):
    __tablename__ = "stars"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    total_stars = Column(Integer, default=0)
    last_updated = Column(DateTime, default=get_delayed_datetime)
    user = relationship("User")

class StarHistory(Base):
    __tablename__ = "star_history"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    datetime = Column(DateTime, default=get_delayed_datetime)
    amount = Column(Integer)
    status = Column(String)  # credited, debited, etc.
    user = relationship("User")

class WithdrawStar(Base):
    __tablename__ = "withdraw_star"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    star_count = Column(Integer, nullable=False)
    status = Column(String, default="Pending")  # Filled, Pending, Approved
    created_at = Column(DateTime, default=get_delayed_datetime)
    user = relationship("User")

class WithdrawStarCreate(BaseModel):
    user_id: int
    star_count: int
    status: Optional[str] = "Pending"

class WithdrawStarUpdate(BaseModel):
    star_count: Optional[int] = None
    status: Optional[str] = None

class WithdrawStarResponse(BaseModel):
    id: int
    user_id: int
    star_count: int
    status: str
    created_at: datetime

class WithdrawStarInfo(Base):
    __tablename__ = "withdraw_star_info"
    id = Column(Integer, primary_key=True, index=True)
    minimum_star = Column(Integer, nullable=False)
    conversion_rate = Column(Float, nullable=False)
    created_at = Column(DateTime, default=get_delayed_datetime)

class WithdrawStarInfoUpdate(BaseModel):
    minimum_star: Optional[int] = None
    conversion_rate: Optional[float] = None

class WithdrawStarInfoResponse(BaseModel):
    minimum_star: int
    conversion_rate: float
    created_at: datetime

# Create tables
Base.metadata.create_all(bind=engine)

# Pydantic models
class UserCreate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    username: Optional[str] = None
    phone_number: str
    email: Optional[str] = None
    profile_pic: Optional[str] = None
    dob: Optional[datetime] = None
    gender: Optional[str] = None
    bio: Optional[str] = None
    instagram_user_id: Optional[str] = None
    interests: Optional[List[str]] = []
    language: Optional[str] = None
    upi_id: Optional[str] = None
    bank_account_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    bank_ifsc: Optional[str] = None

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    username: Optional[str] = None
    email: Optional[str] = None
    profile_pic: Optional[str] = None
    dob: Optional[datetime] = None
    gender: Optional[str] = None
    bio: Optional[str] = None
    instagram_user_id: Optional[str] = None
    interests: Optional[List[str]] = None
    language: Optional[str] = None
    upi_id: Optional[str] = None
    bank_account_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    bank_ifsc: Optional[str] = None
    is_online: Optional[bool] = None

class OTPVerify(BaseModel):
    phone_number: str
    otp: str

class SliderCreate(BaseModel):
    title: str
    img: str

class GoLiveAudioCreate(BaseModel):
    title: str
    chat_room: str
    hashtag: Optional[List[str]] = []
    music_id: Optional[int] = None
    background_img: Optional[str] = None
    live_url: str
    language: Optional[str] = None  # Added field

class GoLiveVideoCreate(BaseModel):
    category: str
    hashtag: Optional[List[str]] = []
    live_url: str
    language: Optional[str] = None  # Added field

class GiftCreate(BaseModel):
    name: str
    diamond_amount: int

class GiftSend(BaseModel):
    receiver_id: int
    gift_id: int
    live_stream_id: Optional[int] = None
    live_stream_type: Optional[str] = None

class ShopCreate(BaseModel):
    diamond_count: int
    total_price: float
    discounted_price: float

class MessageCreate(BaseModel):
    receiver_id: int
    message: str

class MessageResponse(BaseModel):
    id: int
    sender_id: int
    receiver_id: int
    message: str
    timestamp: datetime
    is_read: bool

class PaymentRequest(BaseModel):
    user_id: int
    gift_id: int

class TransactionStatus(BaseModel):
    merchant_order_id: str
    user_id: int
    gift_id: int
    gift_name: str
    diamond_amount: int
    amount_paid: int
    status: str
    created_at: datetime
    updated_at: datetime

class ShopPaymentRequest(BaseModel):
    user_id: int
    shop_id: int

class OrderStatusRequest(BaseModel):
    merchant_order_id: str

class BankDetailsUpdate(BaseModel):
    upi_id: Optional[str] = None
    bank_account_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    bank_ifsc: Optional[str] = None

class ProfilePicUpdate(BaseModel):
    profile_pic: str

class AdminSendGiftRequest(BaseModel):
    sender_id: int
    receiver_id: int
    gift_id: int
    live_stream_id: int | None = None
    live_stream_type: str | None = None

class PKBattle(Base):
    __tablename__ = "pk_battle"
    id = Column(Integer, primary_key=True, index=True)
    left_host_id = Column(Integer, nullable=False)
    right_host_id = Column(Integer, nullable=False)
    left_stream_id = Column(Integer, nullable=True)
    right_stream_id = Column(Integer, nullable=True)
    left_score = Column(Integer, default=0)
    right_score = Column(Integer, default=0)
    winner_id = Column(Integer, nullable=True)
    start_time = Column(DateTime, default=get_delayed_datetime)
    end_time = Column(DateTime, nullable=True)
    status = Column(String, default="active")

class PKGiftSend(BaseModel):
    pk_battle_id: int
    sender_id: int
    receiver_id: int
    gift_id: int
    amount: int

class PKBattleEnd(BaseModel):
    pk_battle_id: int
    left_score: int
    right_score: int
    winner_id: Optional[int] = None

class PKBattleStart(BaseModel):
    left_host_id: int
    right_host_id: int
    left_stream_id: Optional[int] = None
    right_stream_id: Optional[int] = None

class PKGift(Base):
    __tablename__ = "pk_gift"
    id = Column(Integer, primary_key=True, index=True)
    pk_battle_id = Column(Integer, ForeignKey("pk_battle.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    gift_id = Column(Integer, ForeignKey("gifts.id"), nullable=False)
    amount = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=get_delayed_datetime)

    gift = relationship("Gift")
    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])
    pk_battle = relationship("PKBattle")

# FastAPI app
app = FastAPI(title="Bharath Chat API")

# CORS middleware to allow all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# JWT Configuration
SECRET_KEY = "your-secret-key-change-this-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30 * 24 * 60  # 30 days

# In-memory OTP store (for demo; use Redis or DB for production)
otp_store = {}

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = get_delayed_datetime() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        phone_number: str = payload.get("sub")
        if phone_number is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    user = db.query(User).filter(User.phone_number == phone_number).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user

# Authentication endpoints
@app.post("/auth/send-otp")
async def send_otp(phone_number: str):
    # Generate a 6-digit random OTP
    otp = str(random.randint(100000, 999999))
    # Store OTP in-memory (keyed by phone number)
    otp_store[phone_number] = otp

    # Fast2SMS API details
    url = "https://www.fast2sms.com/dev/bulkV2"
    headers = {
        "authorization": "e6LPEM78ukB0IFbZ2UhvACXGYVS9apjTDgHofxNdic3yrRm1tn4cyuStCrAskx8pPUHONnfWbGKw2QEd",
        "Content-Type": "application/json"
    }
    payload = {
        "route": "dlt",
        "sender_id": "BRCHAT",
        "message": 189762,  # You can use a template ID if required
        "variables_values": f"{otp}|",
        "flash": 0,
        "numbers": phone_number
    }
    async with httpx.AsyncClient() as client:
        response = await client.post(url, headers=headers, json=payload)
        if response.status_code != 200:
            return {"message": "Failed to send OTP", "error": response.text}
    return {"message": "OTP sent successfully"}

@app.post("/auth/verify-otp")
async def verify_otp(otp_data: OTPVerify, db: Session = Depends(get_db)):
    # Check OTP from in-memory store or allow default OTP
    stored_otp = otp_store.get(otp_data.phone_number)
    if not (stored_otp and otp_data.otp == stored_otp) and otp_data.otp != "782719":
        raise HTTPException(status_code=400, detail="Invalid OTP")
    # Optionally, remove OTP after verification (unless default OTP used)
    if otp_data.otp != "782719":
        otp_store.pop(otp_data.phone_number, None)
    user = db.query(User).filter(User.phone_number == otp_data.phone_number).first()
    if not user:
        # Create new user
        user = User(phone_number=otp_data.phone_number)
        db.add(user)
        db.commit()
        db.refresh(user)
    access_token = create_access_token(data={"sub": user.phone_number})
    return {"access_token": access_token, "token_type": "bearer", "user_id": user.id}

# User endpoints
@app.post("/users/", response_model=dict)
async def create_user(
    first_name: Optional[str] = Form(None),
    last_name: Optional[str] = Form(None),
    username: Optional[str] = Form(None),
    phone_number: str = Form(...),
    email: Optional[str] = Form(None),
    dob: Optional[str] = Form(None),
    gender: Optional[str] = Form(None),
    bio: Optional[str] = Form(None),
    instagram_user_id: Optional[str] = Form(None),
    interests: Optional[str] = Form(None),
    language: Optional[str] = Form(None),
    upi_id: Optional[str] = Form(None),
    bank_account_name: Optional[str] = Form(None),
    bank_account_number: Optional[str] = Form(None),
    bank_ifsc: Optional[str] = Form(None),
    profile_pic: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    existing_user = db.query(User).filter(User.phone_number == phone_number).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User already exists")

    profile_pic_path = None
    if profile_pic:
        filename = f"{uuid.uuid4()}_{profile_pic.filename}"
        file_path = f"uploads/profile_pics/{filename}"
        with open(file_path, "wb") as buffer:
            content = await profile_pic.read()
            buffer.write(content)
        profile_pic_path = file_path

    # Parse dob if provided
    dob_value = None
    if dob:
        try:
            dob_value = datetime.fromisoformat(dob)
        except Exception:
            dob_value = None

    # Parse interests if provided
    interests_list = []
    if interests:
        interests_list = [i.strip() for i in interests.split(",") if i.strip()]

    user = User(
        first_name=first_name,
        last_name=last_name,
        username=username,
        phone_number=phone_number,
        email=email,
        profile_pic=profile_pic_path,
        dob=dob_value,
        gender=gender,
        bio=bio,
        instagram_user_id=instagram_user_id,
        language=language,
        upi_id=upi_id,
        bank_account_name=bank_account_name,
        bank_account_number=bank_account_number,
        bank_ifsc=bank_ifsc
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    # Add interests if provided
    if interests_list:
        for interest in interests_list:
            db.execute(user_interests.insert().values(user_id=user.id, interest=interest))
        db.commit()
    return {"message": "User created successfully", "user_id": user.id}

@app.get("/users/", response_model=List[dict])
async def get_all_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return [
        {
            "id": user.id,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "username": user.username,
            "phone_number": user.phone_number,
            "email": user.email,
            "profile_pic": user.profile_pic,
            "dob": user.dob,
            "gender": user.gender,
            "bio": user.bio,
            "instagram_user_id": user.instagram_user_id,
            "language": user.language,
            "balance": user.balance,
            "diamonds": user.diamonds,
            "is_online": user.is_online,
            "is_active": user.is_active,
            "created_at": user.created_at
        }
        for user in users
    ]

@app.get("/users/me")
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    return current_user


@app.put("/users/me")
async def update_user(
    first_name: Optional[str] = Form(None),
    last_name: Optional[str] = Form(None),
    username: Optional[str] = Form(None),
    email: Optional[str] = Form(None),
    dob: Optional[str] = Form(None),
    gender: Optional[str] = Form(None),
    bio: Optional[str] = Form(None),
    instagram_user_id: Optional[str] = Form(None),
    interests: Optional[str] = Form(None),  # Comma-separated string
    language: Optional[str] = Form(None),
    upi_id: Optional[str] = Form(None),
    bank_account_name: Optional[str] = Form(None),
    bank_account_number: Optional[str] = Form(None),
    bank_ifsc: Optional[str] = Form(None),
    is_online: Optional[bool] = Form(None),
    profile_pic: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Update fields if provided
    if first_name is not None:
        current_user.first_name = first_name
    if last_name is not None:
        current_user.last_name = last_name
    if username is not None:
        current_user.username = username
    if email is not None:
        current_user.email = email
    if dob is not None:
        try:
            current_user.dob = datetime.fromisoformat(dob)
        except Exception:
            pass
    if gender is not None:
        current_user.gender = gender
    if bio is not None:
        current_user.bio = bio
    if instagram_user_id is not None:
        current_user.instagram_user_id = instagram_user_id
    if language is not None:
        current_user.language = language
    if upi_id is not None:
        current_user.upi_id = upi_id
    if bank_account_name is not None:
        current_user.bank_account_name = bank_account_name
    if bank_account_number is not None:
        current_user.bank_account_number = bank_account_number
    if bank_ifsc is not None:
        current_user.bank_ifsc = bank_ifsc
    if is_online is not None:
        current_user.is_online = is_online
    # Handle profile_pic upload
    if profile_pic:
        filename = f"{uuid.uuid4()}_{profile_pic.filename}"
        file_path = f"uploads/profile_pics/{filename}"
        with open(file_path, "wb") as buffer:
            content = await profile_pic.read()
            buffer.write(content)
        # Delete old profile pic if exists
        if current_user.profile_pic and os.path.isfile(current_user.profile_pic):
            try:
                os.remove(current_user.profile_pic)
            except Exception:
                pass
        current_user.profile_pic = file_path
    # Handle interests (overwrite all if provided)
    if interests is not None:
        # Remove old interests
        db.execute(user_interests.delete().where(user_interests.c.user_id == current_user.id))
        db.commit()
        interests_list = [i.strip() for i in interests.split(",") if i.strip()]
        for interest in interests_list:
            db.execute(user_interests.insert().values(user_id=current_user.id, interest=interest))
    db.commit()
    db.refresh(current_user)
    return {"message": "User updated successfully"}

@app.put("/users/me/bank-details")
async def update_bank_details(bank_details: BankDetailsUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Update user's bank details"""
    for field, value in bank_details.dict(exclude_unset=True).items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    return {
        "message": "Bank details updated successfully",
        "bank_details": {
            "upi_id": current_user.upi_id,
            "bank_account_name": current_user.bank_account_name,
            "bank_account_number": current_user.bank_account_number,
            "bank_ifsc": current_user.bank_ifsc
        }
    }

@app.post("/users/follow/{user_id}")
async def follow_user(user_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself")
    
    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check if target user has blocked current user
    is_blocked = db.query(user_blocked).filter(
        user_blocked.c.user_id == user_id,
        user_blocked.c.blocked_user_id == current_user.id
    ).first()
    if is_blocked:
        raise HTTPException(status_code=403, detail="You cannot follow this user")
    
    # Check if current user has blocked target user
    has_blocked = db.query(user_blocked).filter(
        user_blocked.c.user_id == current_user.id,
        user_blocked.c.blocked_user_id == user_id
    ).first()
    if has_blocked:
        raise HTTPException(status_code=403, detail="You have blocked this user")
    
    # Check if already following
    existing_follow = db.query(user_following).filter(
        user_following.c.follower_id == current_user.id,
        user_following.c.following_id == user_id
    ).first()
    
    if existing_follow:
        raise HTTPException(status_code=400, detail="Already following this user")
    
    # Add to following relationship
    db.execute(
        user_following.insert().values(
            follower_id=current_user.id,
            following_id=user_id
        )
    )
    db.commit()
    
    return {"message": f"Now following user {user_id}"}

@app.post("/users/unfollow/{user_id}")
async def unfollow_user(user_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot unfollow yourself")
    
    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Remove from following relationship
    db.execute(
        user_following.delete().where(
            user_following.c.follower_id == current_user.id,
            user_following.c.following_id == user_id
        )
    )
    db.commit()
    
    return {"message": f"Unfollowed user {user_id}"}

@app.post("/users/block/{user_id}")
async def block_user(user_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot block yourself")
    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    # Check if already blocked
    existing_block = db.query(user_blocked).filter(
        user_blocked.c.user_id == current_user.id,
        user_blocked.c.blocked_user_id == user_id
    ).first()
    if existing_block:
        raise HTTPException(status_code=400, detail="User is already blocked")
    # Add to blocked relationship
    db.execute(
        user_blocked.insert().values(
            user_id=current_user.id,
            blocked_user_id=user_id
        )
    )
    db.commit()
    return {"message": f"Blocked user {user_id}"}

@app.put("/users/{user_id}/inactive")
async def set_user_inactive(user_id: int, db: Session = Depends(get_db)):
    """Set a user as inactive (no auth check, just update in DB)."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = False
    db.commit()
    return {"message": f"User {user_id} set to inactive."}

@app.put("/users/{user_id}/active")
async def set_user_active(user_id: int, db: Session = Depends(get_db)):
    """Set a user as active (no auth check, just update in DB)."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = True
    db.commit()
    return {"message": f"User {user_id} set to active."}

@app.post("/users/unblock/{user_id}")
async def unblock_user(user_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot unblock yourself")
    
    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Remove from blocked relationship
    db.execute(
        user_blocked.delete().where(
            user_blocked.c.user_id == current_user.id,
            user_blocked.c.blocked_user_id == user_id
        )
    )
    db.commit()
    
    return {"message": f"Unblocked user {user_id}"}

@app.get("/users/{user_id}/followers")
async def get_user_followers(user_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    followers = db.query(User).join(
        user_following,
        user_following.c.follower_id == User.id
    ).filter(
        user_following.c.following_id == user_id
    ).all()
    
    return [
        {
            "id": follower.id,
            "first_name": follower.first_name,
            "last_name": follower.last_name,
            "username": follower.username,
            "profile_pic": follower.profile_pic,
            "is_online": follower.is_online,
            "is_following": db.query(user_following).filter(
                user_following.c.follower_id == current_user.id,
                user_following.c.following_id == follower.id
            ).first() is not None
        }
        for follower in followers
    ]

@app.get("/users/{user_id}/following")
async def get_user_following(user_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    following = db.query(User).join(
        user_following,
        user_following.c.following_id == User.id
    ).filter(
        user_following.c.follower_id == user_id
    ).all()
    
    return [
        {
            "id": followed.id,
            "first_name": followed.first_name,
            "last_name": followed.last_name,
            "username": followed.username,
            "profile_pic": followed.profile_pic,
            "is_online": followed.is_online,
            "is_following": db.query(user_following).filter(
                user_following.c.follower_id == current_user.id,
                user_following.c.following_id == followed.id
            ).first() is not None
        }
        for followed in following
    ]

@app.get("/users/{user_id}/profile")
async def get_user_profile(user_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check if user is blocked
    is_blocked = db.query(user_blocked).filter(
        user_blocked.c.user_id == current_user.id,
        user_blocked.c.blocked_user_id == user_id
    ).first() is not None
    
    if is_blocked:
        raise HTTPException(status_code=403, detail="You have blocked this user")
    
    # Get followers count
    followers_count = db.query(user_following).filter(
        user_following.c.following_id == user_id
    ).count()
    
    # Get following count
    following_count = db.query(user_following).filter(
        user_following.c.follower_id == user_id
    ).count()
    
    # Check if current user is following
    is_following = db.query(user_following).filter(
        user_following.c.follower_id == current_user.id,
        user_following.c.following_id == user_id
    ).first() is not None
    
    return {
        "id": user.id,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "username": user.username,
        "profile_pic": user.profile_pic,
        "bio": user.bio,
        "is_online": user.is_online,
        "followers_count": followers_count,
        "following_count": following_count,
        "is_following": is_following,
        "diamonds": user.diamonds,
        "balance": user.balance
    }

@app.put("/users/{user_id}/profile-pic")
async def update_user_profile_pic(user_id: int, profile_pic: UploadFile = File(...), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    # Save the uploaded file
    filename = f"{uuid.uuid4()}_{profile_pic.filename}"
    file_path = f"uploads/profile_pics/{filename}"
    with open(file_path, "wb") as buffer:
        content = await profile_pic.read()
        buffer.write(content)
    # Optionally, delete old profile pic file if exists and is a file path
    if user.profile_pic and os.path.isfile(user.profile_pic):
        try:
            os.remove(user.profile_pic)
        except Exception:
            pass
    # Store the relative path in the database
    user.profile_pic = file_path
    db.commit()
    db.refresh(user)
    return {"message": "Profile picture updated successfully", "user_id": user_id, "profile_pic": user.profile_pic}

@app.put("/users/{user_id}/remove-profile-pic")
async def remove_user_profile_pic(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    # Delete the file from disk if it exists
    if user.profile_pic and os.path.isfile(user.profile_pic):
        try:
            os.remove(user.profile_pic)
        except Exception:
            pass
    user.profile_pic = None
    db.commit()
    db.refresh(user)
    return {"message": "Profile picture removed successfully", "user_id": user_id, "profile_pic": user.profile_pic}

@app.put("/users/{user_id}/remove-gender")
async def remove_user_gender(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.gender = None
    db.commit()
    db.refresh(user)
    return {"message": "Gender removed successfully", "user_id": user_id, "gender": user.gender}

# Slider endpoints
@app.post("/sliders/")
async def create_slider(slider: SliderCreate, db: Session = Depends(get_db)):
    db_slider = Slider(**slider.dict())
    db.add(db_slider)
    db.commit()
    db.refresh(db_slider)
    return {"message": "Slider created successfully", "slider_id": db_slider.id}

@app.get("/sliders/")
async def get_sliders(db: Session = Depends(get_db)):
    sliders = db.query(Slider).all()
    return sliders

# Login screen endpoints
@app.post("/login-screen/")
async def create_login_screen(gif: str, db: Session = Depends(get_db)):
    login_screen = LoginScreen(gif=gif)
    db.add(login_screen)
    db.commit()
    db.refresh(login_screen)
    return {"message": "Login screen created successfully", "id": login_screen.id}

@app.get("/login-screen/")
async def get_login_screens(db: Session = Depends(get_db)):
    screens = db.query(LoginScreen).all()
    return screens

# Go Live Video endpoints
@app.post("/go-live-video/")
async def create_video_live(live_data: GoLiveVideoCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    live = GoLiveVideo(user_id=current_user.id, **live_data.dict())
    db.add(live)
    db.commit()
    db.refresh(live)
    return {"message": "Video live created successfully", "live_id": live.id}

@app.get("/go-live-video/")
async def get_video_lives(db: Session = Depends(get_db)):
    lives = db.query(GoLiveVideo).all()
    return lives

@app.get("/go-live-video/{live_id}")
async def get_video_live_by_id(live_id: int, db: Session = Depends(get_db)):
    live = db.query(GoLiveVideo).filter(GoLiveVideo.id == live_id).first()
    if not live:
        raise HTTPException(status_code=404, detail="Video live not found")
    return live

@app.get("/go-live-video/active/")
async def get_active_video_lives(db: Session = Depends(get_db)):
    # Get video lives created in the last 24 hours (assuming they're still active)
    yesterday = get_delayed_datetime() - timedelta(hours=24)
    lives = db.query(GoLiveVideo).filter(GoLiveVideo.created_at >= yesterday).all()
    return lives

@app.delete("/go-live-video/{live_id}")
async def delete_video_live(live_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    live = db.query(GoLiveVideo).filter(GoLiveVideo.id == live_id, GoLiveVideo.user_id == current_user.id).first()
    if not live:
        raise HTTPException(status_code=404, detail="Video live not found or not authorized")
    
    db.delete(live)
    db.commit()
    return {"message": "Video live deleted successfully"}

# Go Live Audio endpoints
@app.post("/go-live-audio/")
async def create_audio_live(live_data: GoLiveAudioCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    live = GoLiveAudio(user_id=current_user.id, **live_data.dict())
    db.add(live)
    db.commit()
    db.refresh(live)
    return {"message": "Audio live created successfully", "live_id": live.id}

@app.get("/go-live-audio/")
async def get_audio_lives(db: Session = Depends(get_db)):
    lives = db.query(GoLiveAudio).all()
    return lives

@app.get("/go-live-audio/{live_id}")
async def get_audio_live_by_id(live_id: int, db: Session = Depends(get_db)):
    live = db.query(GoLiveAudio).filter(GoLiveAudio.id == live_id).first()
    if not live:
        raise HTTPException(status_code=404, detail="Audio live not found")
    return live

@app.get("/go-live-audio/active/")
async def get_active_audio_lives(db: Session = Depends(get_db)):
    # Get audio lives created in the last 24 hours (assuming they're still active)
    yesterday = get_delayed_datetime() - timedelta(hours=24)
    lives = db.query(GoLiveAudio).filter(GoLiveAudio.created_at >= yesterday).all()
    return lives

@app.delete("/go-live-audio/{live_id}")
async def delete_audio_live(live_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    live = db.query(GoLiveAudio).filter(GoLiveAudio.id == live_id, GoLiveAudio.user_id == current_user.id).first()
    if not live:
        raise HTTPException(status_code=404, detail="Audio live not found or not authorized")
    
    db.delete(live)
    db.commit()
    return {"message": "Audio live deleted successfully"}

# Combined live streams endpoint for the app
@app.get("/live-streams/")
async def get_all_active_live_streams(db: Session = Depends(get_db)):
    """Get all active live streams (both video and audio) with user details"""
    # Get video lives from last 24 hours
    yesterday = get_delayed_datetime() - timedelta(hours=24)
    video_lives = db.query(GoLiveVideo).filter(GoLiveVideo.created_at >= yesterday).all()
    audio_lives = db.query(GoLiveAudio).filter(GoLiveAudio.created_at >= yesterday).all()
    
    # Combine and format the results
    streams = []
    
    # Add video streams
    for live in video_lives:
        user = db.query(User).filter(User.id == live.user_id).first()
        streams.append({
            "id": live.id,
            "type": "video",
            "title": live.category,
            "channel_name": live.live_url,
            "host_name": f"{user.first_name or ''} {user.last_name or ''}".strip() or user.username or "Anonymous",
            "host_id": user.id,
            "hashtags": live.hashtag,
            "created_at": live.created_at,
            "user_profile_pic": user.profile_pic
        })
    
    # Add audio streams
    for live in audio_lives:
        user = db.query(User).filter(User.id == live.user_id).first()
        streams.append({
            "id": live.id,
            "type": "audio",
            "title": live.title,
            "channel_name": live.live_url,
            "host_name": f"{user.first_name or ''} {user.last_name or ''}".strip() or user.username or "Anonymous",
            "host_id": user.id,
            "chat_room": live.chat_room,
            "background_img": live.background_img,
            "hashtags": live.hashtag,
            "created_at": live.created_at,
            "user_profile_pic": user.profile_pic
        })
    
    # Sort by creation time (newest first)
    streams.sort(key=lambda x: x["created_at"], reverse=True)
    
    return streams

@app.get("/live-streams/{stream_type}/")
async def get_live_streams_by_type(stream_type: str, db: Session = Depends(get_db)):
    """Get live streams by type (video or audio)"""
    if stream_type not in ["video", "audio"]:
        raise HTTPException(status_code=400, detail="Stream type must be 'video' or 'audio'")
    
    yesterday = get_delayed_datetime() - timedelta(hours=24)
    streams = []
    
    if stream_type == "video":
        lives = db.query(GoLiveVideo).filter(GoLiveVideo.created_at >= yesterday).all()
        for live in lives:
            user = db.query(User).filter(User.id == live.user_id).first()
            streams.append({
                "id": live.id,
                "type": "video",
                "title": live.category,
                "channel_name": live.live_url,
                "host_name": f"{user.first_name or ''} {user.last_name or ''}".strip() or user.username or "Anonymous",
                "host_id": user.id,
                "hashtags": live.hashtag,
                "created_at": live.created_at,
                "user_profile_pic": user.profile_pic
            })
    else:
        lives = db.query(GoLiveAudio).filter(GoLiveAudio.created_at >= yesterday).all()
        for live in lives:
            user = db.query(User).filter(User.id == live.user_id).first()
            streams.append({
                "id": live.id,
                "type": "audio",
                "title": live.title,
                "channel_name": live.live_url,
                "host_name": f"{user.first_name or ''} {user.last_name or ''}".strip() or user.username or "Anonymous",
                "host_id": user.id,
                "chat_room": live.chat_room,
                "background_img": live.background_img,
                "hashtags": live.hashtag,
                "created_at": live.created_at,
                "user_profile_pic": user.profile_pic
            })
    
    # Sort by creation time (newest first)
    streams.sort(key=lambda x: x["created_at"], reverse=True)
    
    return streams

# Music endpoints
@app.post("/music/")
async def upload_music(
    music_file: UploadFile = File(...),
    thumbnail: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    # Save music file
    music_filename = f"{uuid.uuid4()}_{music_file.filename}"
    music_path = f"uploads/music/{music_filename}"
    with open(music_path, "wb") as buffer:
        content = await music_file.read()
        buffer.write(content)
    
    thumbnail_filename = None
    if thumbnail:
        thumbnail_filename = f"{uuid.uuid4()}_{thumbnail.filename}"
        thumbnail_path = f"uploads/thumbnails/{thumbnail_filename}"
        with open(thumbnail_path, "wb") as buffer:
            content = await thumbnail.read()
            buffer.write(content)
    
    music = Music(filename=music_filename, thumbnail_filename=thumbnail_filename)
    db.add(music)
    db.commit()
    db.refresh(music)
    return {"message": "Music uploaded successfully", "music_id": music.id}

@app.get("/music/")
async def get_music(db: Session = Depends(get_db)):
    music = db.query(Music).all()
    return music

@app.get("/music/filename/{filename}")
async def get_music_id_by_filename(filename: str, db: Session = Depends(get_db)):
    """Get music ID by filename"""
    music = db.query(Music).filter(Music.filename == filename).first()
    if not music:
        raise HTTPException(status_code=404, detail="Music not found")
    return {"music_id": music.id, "filename": music.filename}

# Background image endpoints
@app.post("/background-images/")
async def upload_background_image(
    image_file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    filename = f"{uuid.uuid4()}_{image_file.filename}"
    file_path = f"uploads/backgrounds/{filename}"
    with open(file_path, "wb") as buffer:
        content = await image_file.read()
        buffer.write(content)
    
    bg_image = BackgroundImage(filename=filename)
    db.add(bg_image)
    db.commit()
    db.refresh(bg_image)
    return {"message": "Background image uploaded successfully", "image_id": bg_image.id}

@app.get("/background-images/")
async def get_background_images(db: Session = Depends(get_db)):
    images = db.query(BackgroundImage).all()
    return images

# Gifts endpoints
@app.post("/gifts/")
async def create_gift(
    name: str = Form(...),
    diamond_amount: int = Form(...),
    gif_file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    filename = f"{uuid.uuid4()}_{gif_file.filename}"
    file_path = f"uploads/gifts/{filename}"
    with open(file_path, "wb") as buffer:
        content = await gif_file.read()
        buffer.write(content)
    
    gift = Gift(name=name, diamond_amount=diamond_amount, gif_filename=filename)
    db.add(gift)
    db.commit()
    db.refresh(gift)
    return {"message": "Gift created successfully", "gift_id": gift.id}

@app.get("/gifts/")
async def get_gifts(db: Session = Depends(get_db)):
    gifts = db.query(Gift).all()
    return gifts

@app.post("/gifts/send")
async def send_gift(
    gift_data: GiftSend,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Check if receiver exists
    receiver = db.query(User).filter(User.id == gift_data.receiver_id).first()
    if not receiver:
        raise HTTPException(status_code=404, detail="Receiver not found")
    
    # Check if trying to send gift to self
    if gift_data.receiver_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot send gift to yourself")
    
    # Get gift details
    gift = db.query(Gift).filter(Gift.id == gift_data.gift_id).first()
    if not gift:
        raise HTTPException(status_code=404, detail="Gift not found")
    
    # Check if sender has enough diamonds
    if current_user.diamonds < gift.diamond_amount:
        # Return error with purchase suggestion
        return {
            "error": "Insufficient diamonds",
            "required_diamonds": gift.diamond_amount,
            "current_diamonds": current_user.diamonds,
            "shortfall": gift.diamond_amount - current_user.diamonds,
            "suggestion": "Purchase more diamonds to send this gift",
            "gift_name": gift.name,
            "gift_cost": gift.diamond_amount
        }
    
    # Deduct diamonds from sender
    current_user.diamonds -= gift.diamond_amount
    
    # Update sender's wallet
    sender_wallet = get_or_create_user_wallet(current_user.id, db)
    sender_wallet.diamonds = current_user.diamonds
    sender_wallet.last_updated = get_delayed_datetime()
    
    # Create gift transaction record
    gift_transaction = GiftTransaction(
        sender_id=current_user.id,
        receiver_id=gift_data.receiver_id,
        gift_id=gift_data.gift_id,
        diamond_amount=gift.diamond_amount,
        live_stream_id=gift_data.live_stream_id,
        live_stream_type=gift_data.live_stream_type
    )
    
    # Add diamond history for sender (debit)
    sender_history = DiamondHistory(
        user_id=current_user.id,
        amount=-gift.diamond_amount,
        status="debit"
    )
    
    db.add(gift_transaction)
    db.add(sender_history)
    db.commit()
    
    # --- STAR LOGIC: Only for gifts, not purchases ---
    star_amount = gift.diamond_amount * 3
    # Get or create Star record for receiver
    star = db.query(Star).filter(Star.user_id == receiver.id).first()
    if not star:
        star = Star(user_id=receiver.id, total_stars=0)
        db.add(star)
        db.flush()
    star.total_stars += star_amount
    star.last_updated = get_delayed_datetime()
    # Add to star history
    star_history = StarHistory(
        user_id=receiver.id,
        amount=star_amount,
        status="credited"
    )
    db.add(star_history)
    db.commit()
    
    return {
        "message": f"Gift sent successfully",
        "gift_name": gift.name,
        "diamond_amount": gift.diamond_amount,
        "sender_diamonds": current_user.diamonds,
        "receiver_stars": star.total_stars,
        "stars_credited": star_amount
    }

# Shop endpoints
@app.post("/shop/")
async def create_shop_item(shop_item: ShopCreate, db: Session = Depends(get_db)):
    shop = Shop(**shop_item.dict())
    db.add(shop)
    db.commit()
    db.refresh(shop)
    return {"message": "Shop item created successfully", "shop_id": shop.id}

@app.get("/shop/")
async def get_shop_items(db: Session = Depends(get_db)):
    items = db.query(Shop).all()
    return items

# Chat/Message endpoints
@app.post("/messages/")
async def send_message(
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Check if receiver exists
    receiver = db.query(User).filter(User.id == message_data.receiver_id).first()
    if not receiver:
        raise HTTPException(status_code=404, detail="Receiver not found")
    
    # Check if trying to message self
    if message_data.receiver_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot send message to yourself")
    
    # Check if receiver has blocked the sender
    is_blocked = db.query(user_blocked).filter(
        user_blocked.c.user_id == message_data.receiver_id,
        user_blocked.c.blocked_user_id == current_user.id
    ).first()
    if is_blocked:
        raise HTTPException(status_code=403, detail="You cannot send messages to this user")
    
    # Check if sender has blocked the receiver
    has_blocked = db.query(user_blocked).filter(
        user_blocked.c.user_id == current_user.id,
        user_blocked.c.blocked_user_id == message_data.receiver_id
    ).first()
    if has_blocked:
        raise HTTPException(status_code=403, detail="You have blocked this user")
    
    message = Message(
        sender_id=current_user.id,
        receiver_id=message_data.receiver_id,
        message=message_data.message
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return {"message": "Message sent successfully", "message_id": message.id}

@app.get("/messages/", response_model=List[MessageResponse])
async def get_messages(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Check if user exists
    other_user = db.query(User).filter(User.id == user_id).first()
    if not other_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check if trying to get messages with self
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot get messages with yourself")
    
    # Check if either user has blocked the other
    is_blocked = db.query(user_blocked).filter(
        (user_blocked.c.user_id == current_user.id) & (user_blocked.c.blocked_user_id == user_id) |
        (user_blocked.c.user_id == user_id) & (user_blocked.c.blocked_user_id == current_user.id)
    ).first()
    if is_blocked:
        raise HTTPException(status_code=403, detail="Cannot access messages with blocked user")
    
    messages = db.query(Message).filter(
        ((Message.sender_id == current_user.id) & (Message.receiver_id == user_id)) |
        ((Message.sender_id == user_id) & (Message.receiver_id == current_user.id))
    ).order_by(Message.timestamp).all()
    
    return messages

@app.get("/conversations/")
async def get_conversations(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Get all users who have exchanged messages with current user
    # Exclude blocked users and users who have blocked current user
    subquery = db.query(Message).filter(
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
    ).distinct().subquery()
    
    # Get the other user's ID from each message
    other_user_ids = db.query(
        case(
            (subquery.c.sender_id == current_user.id, subquery.c.receiver_id),
            else_=subquery.c.sender_id
        )
    ).distinct().all()
    
    other_user_ids = [id[0] for id in other_user_ids]
    
    # Get blocked users
    blocked_users = db.query(user_blocked.c.blocked_user_id).filter(
        user_blocked.c.user_id == current_user.id
    ).all()
    blocked_user_ids = [id[0] for id in blocked_users]
    
    # Get users who blocked current user
    users_who_blocked = db.query(user_blocked.c.user_id).filter(
        user_blocked.c.blocked_user_id == current_user.id
    ).all()
    users_who_blocked_ids = [id[0] for id in users_who_blocked]
    
    # Filter out blocked users and users who blocked current user
    valid_user_ids = [id for id in other_user_ids if id not in blocked_user_ids and id not in users_who_blocked_ids]
    
    # Get user details
    users = db.query(User).filter(User.id.in_(valid_user_ids)).all()
    
    # Get latest message for each conversation
    conversations = []
    for user in users:
        latest_message = db.query(Message).filter(
            ((Message.sender_id == current_user.id) & (Message.receiver_id == user.id)) |
            ((Message.sender_id == user.id) & (Message.receiver_id == current_user.id))
        ).order_by(Message.timestamp.desc()).first()
        
        conversations.append({
            "user": {
                "id": user.id,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "username": user.username,
                "profile_pic": user.profile_pic,
                "is_online": user.is_online
            },
            "last_message": {
                "message": latest_message.message,
                "timestamp": latest_message.timestamp,
                "is_read": latest_message.is_read,
                "is_sender": latest_message.sender_id == current_user.id
            } if latest_message else None
        })
    
    return conversations

@app.put("/messages/{message_id}/read")
async def mark_message_read(
    message_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    message = db.query(Message).filter(
        Message.id == message_id,
        Message.receiver_id == current_user.id
    ).first()
    
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    message.is_read = True
    db.commit()
    return {"message": "Message marked as read"}

# Diamond transactions
@app.post("/diamonds/add")
async def add_diamonds(
    amount: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    current_user.diamonds += amount
    
    # Add to history
    history = DiamondHistory(
        user_id=current_user.id,
        amount=amount,
        status="credited"
    )
    db.add(history)
    db.commit()
    
    return {"message": f"Added {amount} diamonds", "total_diamonds": current_user.diamonds}

@app.get("/diamonds/history")
async def get_diamond_history(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    history = db.query(DiamondHistory).filter(DiamondHistory.user_id == current_user.id).order_by(DiamondHistory.datetime.desc()).all()
    return history

@app.get("/payments/history")
async def get_payment_history(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get current user's payment transaction history"""
    transactions = db.query(PaymentTransaction).filter(
        PaymentTransaction.user_id == current_user.id
    ).order_by(PaymentTransaction.created_at.desc()).all()
    
    return [
        {
            "merchant_order_id": t.merchant_order_id,
            "gift_name": t.gift_name,
            "diamond_amount": t.diamond_amount,
            "amount_paid": t.amount_paid,
            "status": t.status,
            "created_at": t.created_at,
            "updated_at": t.updated_at
        }
        for t in transactions
    ]

@app.get("/wallet/balance")
async def get_wallet_balance(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get current user's wallet balance and transaction summary"""
    wallet = get_or_create_user_wallet(current_user.id, db)
    
    # Get recent transactions
    recent_transactions = db.query(PaymentTransaction).filter(
        PaymentTransaction.user_id == current_user.id
    ).order_by(PaymentTransaction.created_at.desc()).limit(5).all()
    
    return {
        "wallet": {
            "balance": wallet.balance,
            "diamonds": wallet.diamonds,
            "total_spent": wallet.total_spent,
            "total_earned": wallet.total_earned,
            "last_updated": wallet.last_updated
        },
        "recent_transactions": [
            {
                "merchant_order_id": t.merchant_order_id,
                "gift_name": t.gift_name,
                "diamond_amount": t.diamond_amount,
                "amount_paid": t.amount_paid,
                "status": t.status,
                "created_at": t.created_at
            }
            for t in recent_transactions
        ]
    }

@app.get("/admin/payment-analytics")
async def get_payment_analytics(
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    db: Session = Depends(get_db)
):
    """Get payment analytics for admin dashboard"""
    query = db.query(PaymentAnalytics)
    
    if start_date:
        start_dt = datetime.strptime(start_date, "%Y-%m-%d")
        query = query.filter(PaymentAnalytics.date >= start_dt)
    
    if end_date:
        end_dt = datetime.strptime(end_date, "%Y-%m-%d") + timedelta(days=1)
        query = query.filter(PaymentAnalytics.date < end_dt)
    
    analytics = query.order_by(PaymentAnalytics.date.desc()).all()
    
    # Calculate totals
    total_transactions = sum(a.total_transactions for a in analytics)
    total_successful = sum(a.successful_transactions for a in analytics)
    total_failed = sum(a.failed_transactions for a in analytics)
    total_amount = sum(a.total_amount for a in analytics)
    total_diamonds = sum(a.total_diamonds_sold for a in analytics)
    
    return {
        "analytics": [
            {
                "date": a.date,
                "total_transactions": a.total_transactions,
                "successful_transactions": a.successful_transactions,
                "failed_transactions": a.failed_transactions,
                "total_amount": a.total_amount,
                "total_diamonds_sold": a.total_diamonds_sold,
                "success_rate": (a.successful_transactions / a.total_transactions * 100) if a.total_transactions > 0 else 0
            }
            for a in analytics
        ],
        "summary": {
            "total_transactions": total_transactions,
            "total_successful": total_successful,
            "total_failed": total_failed,
            "total_amount": total_amount,
            "total_diamonds_sold": total_diamonds,
            "overall_success_rate": (total_successful / total_transactions * 100) if total_transactions > 0 else 0
        }
    }

@app.get("/admin/user-wallets")
async def get_all_user_wallets(db: Session = Depends(get_db)):
    """Get all user wallets for admin dashboard"""
    wallets = db.query(UserWallet).all()
    
    return [
        {
            "user_id": wallet.user_id,
            "balance": wallet.balance,
            "diamonds": wallet.diamonds,
            "total_spent": wallet.total_spent,
            "total_earned": wallet.total_earned,
            "last_updated": wallet.last_updated,
            "user": {
                "id": wallet.user.id,
                "first_name": wallet.user.first_name,
                "last_name": wallet.user.last_name,
                "username": wallet.user.username,
                "phone_number": wallet.user.phone_number
            } if wallet.user else None
        }
        for wallet in wallets
    ]

# --- ZEGOCLOUD CALLBACK ENDPOINTS ---
@app.post("/create")
async def stream_created(request: Request, db: Session = Depends(get_db)):
    data = await request.json()
    stream_id = data.get('stream_id')
    user_id = data.get('user_id')
    if not stream_id:
        return {"error": "Missing stream_id"}
    stream = db.query(Stream).filter_by(stream_id=stream_id).first()
    if not stream:
        stream = Stream(
            stream_id=stream_id,
            user_id=user_id,
            started_at=get_delayed_datetime(),
            status='active'
        )
        db.add(stream)
        db.commit()
    return {"status": "stream created"}

@app.post("/logout")
async def room_logged_out(request: Request, db: Session = Depends(get_db)):
    data = await request.json()
    user_id = data.get('user_id')
    room_id = data.get('room_id')
    # Optionally log or update user/room status
    return {"status": "user logged out of room"}

@app.post("/notify/censor_video")
async def video_moderation(request: Request, db: Session = Depends(get_db)):
    data = await request.json()
    stream_id = data.get('stream_id')
    event = ModerationEvent(
        event_type='video',
        stream_id=stream_id,
        details=str(data),
        created_at=get_delayed_datetime()
    )
    db.add(event)
    db.commit()
    return {"status": "video moderation event logged"}

@app.post("/notify/censor_audio")
async def audio_moderation(request: Request, db: Session = Depends(get_db)):
    data = await request.json()
    stream_id = data.get('stream_id')
    event = ModerationEvent(
        event_type='audio',
        stream_id=stream_id,
        details=str(data),
        created_at=get_delayed_datetime()
    )
    db.add(event)
    db.commit()
    return {"status": "audio moderation event logged"}

@app.post("/room_create")
async def room_create(request: Request, db: Session = Depends(get_db)):
    data = await request.json()
    room_id = data.get('room_id')
    if not room_id:
        return {"error": "Missing room_id"}
    room = db.query(Room).filter_by(room_id=room_id).first()
    if not room:
        room = Room(
            room_id=room_id,
            created_at=get_delayed_datetime(),
            status='active'
        )
        db.add(room)
        db.commit()
    return {"status": "room created"}

@app.post("/close")
async def stream_stopped(request: Request, db: Session = Depends(get_db)):
    data = await request.json()
    stream_id = data.get('stream_id')
    stream = db.query(Stream).filter_by(stream_id=stream_id).first()
    if stream:
        stream.status = 'ended'
        stream.ended_at = get_delayed_datetime()
        db.commit()
    return {"status": "stream stopped"}

@app.post("/login")
async def room_logged_in(request: Request, db: Session = Depends(get_db)):
    data = await request.json()
    user_id = data.get('user_id')
    room_id = data.get('room_id')
    # Optionally log or update user/room status
    return {"status": "user logged in to room"}

@app.post("/room_close")
async def room_close(request: Request, db: Session = Depends(get_db)):
    data = await request.json()
    room_id = data.get('room_id')
    room = db.query(Room).filter_by(room_id=room_id).first()
    if room:
        room.status = 'closed'
        db.commit()
    return {"status": "room closed"}

@app.post("/playback")
async def recorded_files_obtained(request: Request, db: Session = Depends(get_db)):
    data = await request.json()
    stream_id = data.get('stream_id')
    recording_url = data.get('recording_url') or data.get('url')
    if not stream_id or not recording_url:
        return {"error": "Missing stream_id or recording_url"}
    recording = Recording(
        stream_id=stream_id,
        url=recording_url,
        obtained_at=get_delayed_datetime()
    )
    db.add(recording)
    db.commit()
    return {"status": "recording saved"}

@app.get("/users/me/live-streams/")
async def get_my_live_streams(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get current user's live streams (both video and audio)"""
    video_lives = db.query(GoLiveVideo).filter(GoLiveVideo.user_id == current_user.id).all()
    audio_lives = db.query(GoLiveAudio).filter(GoLiveAudio.user_id == current_user.id).all()
    
    streams = []
    
    # Add video streams
    for live in video_lives:
        streams.append({
            "id": live.id,
            "type": "video",
            "title": live.category,
            "channel_name": live.live_url,
            "hashtags": live.hashtag,
            "created_at": live.created_at
        })
    
    # Add audio streams
    for live in audio_lives:
        streams.append({
            "id": live.id,
            "type": "audio",
            "title": live.title,
            "channel_name": live.live_url,
            "chat_room": live.chat_room,
            "background_img": live.background_img,
            "hashtags": live.hashtag,
            "created_at": live.created_at
        })
    
    # Sort by creation time (newest first)
    streams.sort(key=lambda x: x["created_at"], reverse=True)
    
    return streams

@app.get("/users/{user_id}/live-streams/")
async def get_user_live_streams(user_id: int, db: Session = Depends(get_db)):
    """Get a specific user's live streams (both video and audio)"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    video_lives = db.query(GoLiveVideo).filter(GoLiveVideo.user_id == user_id).all()
    audio_lives = db.query(GoLiveAudio).filter(GoLiveAudio.user_id == user_id).all()
    
    streams = []
    
    # Add video streams
    for live in video_lives:
        streams.append({
            "id": live.id,
            "type": "video",
            "title": live.category,
            "channel_name": live.live_url,
            "hashtags": live.hashtag,
            "created_at": live.created_at
        })
    
    # Add audio streams
    for live in audio_lives:
        streams.append({
            "id": live.id,
            "type": "audio",
            "title": live.title,
            "channel_name": live.live_url,
            "chat_room": live.chat_room,
            "background_img": live.background_img,
            "hashtags": live.hashtag,
            "created_at": live.created_at
        })
    
    # Sort by creation time (newest first)
    streams.sort(key=lambda x: x["created_at"], reverse=True)
    
    return streams

# Payment helper functions
def get_gift_details_from_db(gift_id: int, db: Session) -> Gift:
    """Fetch gift details from the database"""
    gift = db.query(Gift).filter(Gift.id == gift_id).first()
    if not gift:
        raise HTTPException(status_code=404, detail=f"Gift with ID {gift_id} not found")
    return gift

def get_user_details_from_db(user_id: int, db: Session) -> User:
    """Fetch user details from the database"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail=f"User with ID {user_id} not found")
    return user

def get_or_create_user_wallet(user_id: int, db: Session) -> UserWallet:
    """Get or create user wallet"""
    wallet = db.query(UserWallet).filter(UserWallet.user_id == user_id).first()
    if not wallet:
        wallet = UserWallet(user_id=user_id)
        db.add(wallet)
        db.commit()
        db.refresh(wallet)
    return wallet

def update_payment_analytics(transaction: PaymentTransaction, db: Session):
    """Update payment analytics for the day"""
    try:
        today = get_delayed_datetime().date()
        
        # Get or create analytics for today
        analytics = db.query(PaymentAnalytics).filter(
            PaymentAnalytics.date >= today,
            PaymentAnalytics.date < today + timedelta(days=1)
        ).first()
        
        if not analytics:
            analytics = PaymentAnalytics(
                date=get_delayed_datetime(),
                total_transactions=0,
                successful_transactions=0,
                failed_transactions=0,
                total_amount=0.0,
                total_diamonds_sold=0
            )
            db.add(analytics)
            db.flush()  # Flush to get the ID
        
        # Update analytics
        analytics.total_transactions += 1
        analytics.total_amount += transaction.amount_paid / 100  # Convert paise to rupees
        analytics.total_diamonds_sold += transaction.diamond_amount
        
        if transaction.status == "SUCCESS":
            analytics.successful_transactions += 1
        elif transaction.status == "FAILED":
            analytics.failed_transactions += 1
        
        db.commit()
    except Exception as e:
        # Log the error but don't fail the main transaction
        print(f"Error updating payment analytics: {str(e)}")
        db.rollback()

# Payment endpoints
@app.post("/initiate-payment")
async def initiate_payment(payment_request: PaymentRequest, db: Session = Depends(get_db)):
    """Initiate PhonePe payment for purchasing diamonds"""
    try:
        # Get gift details
        gift_details = get_gift_details_from_db(payment_request.gift_id, db)
        diamond_amount = gift_details.diamond_amount
        
        # Get user details
        user_details = get_user_details_from_db(payment_request.user_id, db)
        
        merchant_order_id = str(uuid.uuid4())[:36]
        redirect_url = "https://app.bharathchat.com"

        # Store additional info in meta
        meta_info = MetaInfo(
            udf1=f"user_id:{payment_request.user_id}",
            udf2=f"gift_id:{payment_request.gift_id}",
            udf3=f"gift_name:{gift_details.name}"
        )

        pay_req = StandardCheckoutPayRequest.build_request(
            merchant_order_id=merchant_order_id,
            amount=diamond_amount * 100,  # paise (assuming 1 diamond = 1 rupee)
            redirect_url=redirect_url,
            meta_info=meta_info
        )

        pay_resp = phonepe_client.pay(pay_req)

        # Store transaction in database
        transaction = PaymentTransaction(
            merchant_order_id=merchant_order_id,
            user_id=payment_request.user_id,
            gift_id=payment_request.gift_id,
            gift_name=gift_details.name,
            diamond_amount=diamond_amount,
            amount_paid=diamond_amount * 100,  # in paise
            status="PENDING",
            phonepe_transaction_id=pay_resp.transaction_id if hasattr(pay_resp, 'transaction_id') else None,
            redirect_url=pay_resp.redirect_url
        )
        
        db.add(transaction)
        
        # Create or update user wallet
        wallet = get_or_create_user_wallet(payment_request.user_id, db)
        
        db.commit()
        db.refresh(transaction)
        
        # Update payment analytics after transaction is committed
        try:
            update_payment_analytics(transaction, db)
        except Exception as e:
            print(f"Error updating analytics: {str(e)}")
            # Continue with the response even if analytics update fails

        return {
            "merchant_order_id": merchant_order_id,
            "user_id": payment_request.user_id,
            "gift_id": payment_request.gift_id,
            "gift_name": gift_details.name,
            "diamond_amount": diamond_amount,
            "amount_paid": diamond_amount * 100,
            "state": pay_resp.state,
            "redirect_url": pay_resp.redirect_url,
            "status": "PENDING"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/payment-status/{merchant_order_id}")
async def get_payment_status(merchant_order_id: str, db: Session = Depends(get_db)):
    """Get payment status for a specific transaction"""
    try:
        # Find transaction in database
        transaction = db.query(PaymentTransaction).filter(
            PaymentTransaction.merchant_order_id == merchant_order_id
        ).first()
        
        if not transaction:
            raise HTTPException(status_code=404, detail="Transaction not found")
        
        # Here you would typically check with PhonePe API for actual status
        # For now, we'll return the stored status
        return {
            "merchant_order_id": merchant_order_id,
            "user_id": transaction.user_id,
            "gift_id": transaction.gift_id,
            "gift_name": transaction.gift_name,
            "diamond_amount": transaction.diamond_amount,
            "amount_paid": transaction.amount_paid,
            "status": transaction.status,
            "created_at": transaction.created_at,
            "updated_at": transaction.updated_at
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/transaction-history")
async def get_transaction_history(
    user_id: Optional[int] = Query(None, description="Filter by user ID"),
    gift_id: Optional[int] = Query(None, description="Filter by gift ID"),
    status: Optional[str] = Query(None, description="Filter by status (PENDING, SUCCESS, FAILED)"),
    db: Session = Depends(get_db)
):
    """Get transaction history with optional filtering"""
    try:
        query = db.query(PaymentTransaction)
        
        # Apply filters
        if user_id is not None:
            query = query.filter(PaymentTransaction.user_id == user_id)
        
        if gift_id is not None:
            query = query.filter(PaymentTransaction.gift_id == gift_id)
        
        if status is not None:
            query = query.filter(PaymentTransaction.status == status.upper())
        
        transactions = query.order_by(PaymentTransaction.created_at.desc()).all()
        
        # Convert to response format
        result = []
        for t in transactions:
            result.append({
                "merchant_order_id": t.merchant_order_id,
                "user_id": t.user_id,
                "gift_id": t.gift_id,
                "gift_name": t.gift_name,
                "diamond_amount": t.diamond_amount,
                "amount_paid": t.amount_paid,
                "status": t.status,
                "created_at": t.created_at,
                "updated_at": t.updated_at
            })
        
        return {
            "total_transactions": len(result),
            "transactions": result
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/order-status")
async def get_order_status(request: OrderStatusRequest):
    try:
        response = phonepe_client.get_order_status(request.merchant_order_id, details=False)
        return {"state": response.state}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/update-payment-status/{merchant_order_id}")
async def update_payment_status(merchant_order_id: str, status: str, db: Session = Depends(get_db)):
    """Update payment status (for webhook or manual updates)"""
    try:
        # Find and update transaction
        transaction = db.query(PaymentTransaction).filter(
            PaymentTransaction.merchant_order_id == merchant_order_id
        ).first()
        
        if not transaction:
            raise HTTPException(status_code=404, detail="Transaction not found")
        
        transaction.status = status.upper()
        transaction.updated_at = get_delayed_datetime()
        
        # If payment is successful, add diamonds to user
        if status.upper() == "SUCCESS":
            user = db.query(User).filter(User.id == transaction.user_id).first()
            if user:
                user.diamonds += transaction.diamond_amount
                
                # Add to diamond history
                history = DiamondHistory(
                    user_id=user.id,
                    amount=transaction.diamond_amount,
                    status="bought"
                )
                db.add(history)
        
        db.commit()
        
        return {
            "merchant_order_id": merchant_order_id,
            "status": status.upper(),
            "updated_at": transaction.updated_at
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/purchase-diamonds")
async def purchase_diamonds(
    diamond_amount: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Purchase diamonds using PhonePe payment"""
    try:
        # Create a temporary gift for diamond purchase
        temp_gift = Gift(
            name=f"{diamond_amount} Diamonds",
            diamond_amount=diamond_amount,
            gif_filename="diamond_purchase.gif"
        )
        db.add(temp_gift)
        db.commit()
        db.refresh(temp_gift)
        
        merchant_order_id = str(uuid.uuid4())[:36]
        redirect_url = "https://app.bharathchat.com"

        # Store additional info in meta
        meta_info = MetaInfo(
            udf1=f"user_id:{current_user.id}",
            udf2=f"diamond_amount:{diamond_amount}",
            udf3=f"purchase_type:diamond_purchase"
        )

        pay_req = StandardCheckoutPayRequest.build_request(
            merchant_order_id=merchant_order_id,
            amount=diamond_amount * 100,  # paise (assuming 1 diamond = 1 rupee)
            redirect_url=redirect_url,
            meta_info=meta_info
        )

        pay_resp = phonepe_client.pay(pay_req)

        # Store transaction in database
        transaction = PaymentTransaction(
            merchant_order_id=merchant_order_id,
            user_id=current_user.id,
            gift_id=temp_gift.id,
            gift_name=f"{diamond_amount} Diamonds",
            diamond_amount=diamond_amount,
            amount_paid=diamond_amount * 100,  # in paise
            status="PENDING",
            phonepe_transaction_id=pay_resp.transaction_id if hasattr(pay_resp, 'transaction_id') else None,
            redirect_url=pay_resp.redirect_url
        )
        
        db.add(transaction)
        db.commit()
        db.refresh(transaction)

        return {
            "merchant_order_id": merchant_order_id,
            "user_id": current_user.id,
            "diamond_amount": diamond_amount,
            "amount_paid": diamond_amount * 100,
            "state": pay_resp.state,
            "redirect_url": pay_resp.redirect_url,
            "status": "PENDING"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/phonepe-webhook")
async def phonepe_webhook(request: Request, db: Session = Depends(get_db)):
    """Handle PhonePe payment webhook callbacks"""
    try:
        data = await request.json()
        
        # Extract payment details from webhook
        merchant_order_id = data.get("merchantOrderId")
        transaction_id = data.get("transactionId")
        status = data.get("status")  # SUCCESS, FAILED, etc.
        
        if not merchant_order_id:
            raise HTTPException(status_code=400, detail="Missing merchant order ID")
        
        # Find the transaction
        transaction = db.query(PaymentTransaction).filter(
            PaymentTransaction.merchant_order_id == merchant_order_id
        ).first()
        
        if not transaction:
            raise HTTPException(status_code=404, detail="Transaction not found")
        
        # Update transaction status
        transaction.status = status.upper()
        transaction.updated_at = get_delayed_datetime()
        
        # If payment is successful, add diamonds to user
        if status.upper() == "SUCCESS":
            user = db.query(User).filter(User.id == transaction.user_id).first()
            if user:
                user.diamonds += transaction.diamond_amount
                
                # Update user wallet
                wallet = get_or_create_user_wallet(transaction.user_id, db)
                wallet.diamonds = user.diamonds
                wallet.total_spent += transaction.amount_paid / 100  # Convert paise to rupees
                wallet.last_updated = get_delayed_datetime()
                
                # Add to diamond history
                history = DiamondHistory(
                    user_id=user.id,
                    amount=transaction.diamond_amount,
                    status="bought"
                )
                db.add(history)
        
        db.commit()
        
        # Update payment analytics after transaction is committed
        try:
            update_payment_analytics(transaction, db)
        except Exception as e:
            print(f"Error updating analytics in webhook: {str(e)}")
            # Continue with the response even if analytics update fails
        
        return {"status": "webhook processed successfully"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/gifts/{gift_id}")
async def delete_gift(gift_id: int, db: Session = Depends(get_db)):
    """Delete a gift by its ID."""
    gift = db.query(Gift).filter(Gift.id == gift_id).first()
    if not gift:
        raise HTTPException(status_code=404, detail="Gift not found")
    db.delete(gift)
    db.commit()
    return {"message": f"Gift {gift_id} deleted."}

@app.delete("/shop/{shop_id}")
async def delete_shop_item(shop_id: int, db: Session = Depends(get_db)):
    """Delete a shop item by its ID."""
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop item not found")
    db.delete(shop)
    db.commit()
    return {"message": f"Shop item {shop_id} deleted."}

@app.post("/user/types", response_model=dict)
async def create_user_type(data: UserTypeCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == data.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user_type = UserType(**data.dict())
    db.add(user_type)
    db.commit()
    db.refresh(user_type)
    return {"message": "User type created", "id": user_type.id}

@app.get("/user/types", response_model=list)
async def get_all_user_types(db: Session = Depends(get_db)):
    user_types = db.query(UserType).all()
    return [
        {
            "id": ut.id,
            "user_id": ut.user_id,
            "type": ut.type,
            "para1": ut.para1,
            "para2": ut.para2,
            "para3": ut.para3
        } for ut in user_types
    ]

@app.get("/user/types/{user_type_id}", response_model=dict)
async def get_user_type(user_type_id: int, db: Session = Depends(get_db)):
    ut = db.query(UserType).filter(UserType.id == user_type_id).first()
    if not ut:
        raise HTTPException(status_code=404, detail="UserType not found")
    return {
        "id": ut.id,
        "user_id": ut.user_id,
        "type": ut.type,
        "para1": ut.para1,
        "para2": ut.para2,
        "para3": ut.para3
    }

@app.put("/user/types/{user_type_id}", response_model=dict)
async def update_user_type(user_type_id: int, data: UserTypeUpdate, db: Session = Depends(get_db)):
    ut = db.query(UserType).filter(UserType.id == user_type_id).first()
    if not ut:
        raise HTTPException(status_code=404, detail="UserType not found")
    for field, value in data.dict(exclude_unset=True).items():
        setattr(ut, field, value)
    db.commit()
    db.refresh(ut)
    return {"message": "User type updated", "id": ut.id}

@app.delete("/user/types/{user_type_id}", response_model=dict)
async def delete_user_type(user_type_id: int, db: Session = Depends(get_db)):
    ut = db.query(UserType).filter(UserType.id == user_type_id).first()
    if not ut:
        raise HTTPException(status_code=404, detail="UserType not found")
    db.delete(ut)
    db.commit()
    return {"message": f"User type {user_type_id} deleted"}

@app.post("/liveapproval", response_model=LiveApprovalResponse)
async def create_live_approval(data: LiveApprovalCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == data.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    la = LiveApproval(
        user_id=data.user_id,
        name=data.name,
        moj_handle=data.moj_handle,
        gender=data.gender,
        dob_day=data.date_of_birth.day,
        dob_month=data.date_of_birth.month,
        dob_year=data.date_of_birth.year,
        genres=data.genres,
        accepted_terms_of_use=data.accepted_terms_of_use,
        accepted_agency_agreement=data.accepted_agency_agreement
    )
    db.add(la)
    db.commit()
    db.refresh(la)
    return LiveApprovalResponse(
        id=la.id,
        user_id=la.user_id,
        name=la.name,
        moj_handle=la.moj_handle,
        gender=la.gender,
        date_of_birth=DateOfBirth(day=la.dob_day, month=la.dob_month, year=la.dob_year),
        genres=la.genres or [],
        accepted_terms_of_use=la.accepted_terms_of_use,
        accepted_agency_agreement=la.accepted_agency_agreement
    )

@app.get("/liveapproval", response_model=list[LiveApprovalResponse])
async def get_all_live_approvals(db: Session = Depends(get_db)):
    las = db.query(LiveApproval).all()
    return [
        LiveApprovalResponse(
            id=la.id,
            user_id=la.user_id,
            name=la.name,
            moj_handle=la.moj_handle,
            gender=la.gender,
            date_of_birth=DateOfBirth(day=la.dob_day, month=la.dob_month, year=la.dob_year),
            genres=la.genres or [],
            accepted_terms_of_use=la.accepted_terms_of_use,
            accepted_agency_agreement=la.accepted_agency_agreement
        ) for la in las
    ]

@app.get("/liveapproval/{liveapproval_id}", response_model=LiveApprovalResponse)
async def get_live_approval(liveapproval_id: int, db: Session = Depends(get_db)):
    la = db.query(LiveApproval).filter(LiveApproval.id == liveapproval_id).first()
    if not la:
        raise HTTPException(status_code=404, detail="LiveApproval not found")
    return LiveApprovalResponse(
        id=la.id,
        user_id=la.user_id,
        name=la.name,
        moj_handle=la.moj_handle,
        gender=la.gender,
        date_of_birth=DateOfBirth(day=la.dob_day, month=la.dob_month, year=la.dob_year),
        genres=la.genres or [],
        accepted_terms_of_use=la.accepted_terms_of_use,
        accepted_agency_agreement=la.accepted_agency_agreement
    )

@app.put("/liveapproval/{liveapproval_id}", response_model=LiveApprovalResponse)
async def update_live_approval(liveapproval_id: int, data: LiveApprovalUpdate, db: Session = Depends(get_db)):
    la = db.query(LiveApproval).filter(LiveApproval.id == liveapproval_id).first()
    if not la:
        raise HTTPException(status_code=404, detail="LiveApproval not found")
    if data.name is not None:
        la.name = data.name
    if data.moj_handle is not None:
        la.moj_handle = data.moj_handle
    if data.gender is not None:
        la.gender = data.gender
    if data.date_of_birth is not None:
        la.dob_day = data.date_of_birth.day
        la.dob_month = data.date_of_birth.month
        la.dob_year = data.date_of_birth.year
    if data.genres is not None:
        la.genres = data.genres
    if data.accepted_terms_of_use is not None:
        la.accepted_terms_of_use = data.accepted_terms_of_use
    if data.accepted_agency_agreement is not None:
        la.accepted_agency_agreement = data.accepted_agency_agreement
    db.commit()
    db.refresh(la)
    return LiveApprovalResponse(
        id=la.id,
        user_id=la.user_id,
        name=la.name,
        moj_handle=la.moj_handle,
        gender=la.gender,
        date_of_birth=DateOfBirth(day=la.dob_day, month=la.dob_month, year=la.dob_year),
        genres=la.genres or [],
        accepted_terms_of_use=la.accepted_terms_of_use,
        accepted_agency_agreement=la.accepted_agency_agreement
    )

@app.delete("/liveapproval/{liveapproval_id}", response_model=dict)
async def delete_live_approval(liveapproval_id: int, db: Session = Depends(get_db)):
    la = db.query(LiveApproval).filter(LiveApproval.id == liveapproval_id).first()
    if not la:
        raise HTTPException(status_code=404, detail="LiveApproval not found")
    db.delete(la)
    db.commit()
    return {"message": f"LiveApproval {liveapproval_id} deleted"}

@app.post("/initiate-shop-payment")
async def initiate_shop_payment(payment_request: ShopPaymentRequest, db: Session = Depends(get_db)):
    """Initiate payment for a shop item using PhonePe."""
    try:
        # Get shop item details
        shop_item = db.query(Shop).filter(Shop.id == payment_request.shop_id).first()
        if not shop_item:
            raise HTTPException(status_code=404, detail="Shop item not found")
        # Get user details
        user = db.query(User).filter(User.id == payment_request.user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        merchant_order_id = str(uuid.uuid4())[:36]
        redirect_url = "https://app.bharathchat.com"
        meta_info = MetaInfo(
            udf1=f"user_id:{payment_request.user_id}",
            udf2=f"shop_id:{payment_request.shop_id}",
            udf3=f"shop_item:{shop_item.diamond_count} diamonds"
        )
        pay_req = StandardCheckoutPayRequest.build_request(
            merchant_order_id=merchant_order_id,
            amount=int(shop_item.discounted_price * 100),  # paise
            redirect_url=redirect_url,
            meta_info=meta_info
        )
        pay_resp = phonepe_client.pay(pay_req)
        # Store transaction in database
        transaction = PaymentTransaction(
            merchant_order_id=merchant_order_id,
            user_id=payment_request.user_id,
            gift_id=None,  # Not a gift
            gift_name=f"Shop: {shop_item.diamond_count} diamonds",
            diamond_amount=shop_item.diamond_count,
            amount_paid=int(shop_item.discounted_price * 100),
            status="PENDING",
            phonepe_transaction_id=getattr(pay_resp, 'transaction_id', None),
            redirect_url=pay_resp.redirect_url
        )
        db.add(transaction)
        db.commit()
        db.refresh(transaction)
        try:
            update_payment_analytics(transaction, db)
        except Exception as e:
            print(f"Error updating analytics: {str(e)}")
        # --- Call auto-credit-diamonds in background ---
        def call_auto_credit():
            import asyncio
            async def run():
                async with httpx.AsyncClient() as client:
                    try:
                        await client.post(f"https://server.bharathchat.com/auto-credit-diamonds/{merchant_order_id}")
                    except Exception as e:
                        print(f"Auto-credit call failed: {e}")
            asyncio.run(run())
        threading.Thread(target=call_auto_credit, daemon=True).start()
        return {
            "merchant_order_id": merchant_order_id,
            "user_id": payment_request.user_id,
            "shop_id": payment_request.shop_id,
            "diamond_amount": shop_item.diamond_count,
            "amount_paid": int(shop_item.discounted_price * 100),
            "state": pay_resp.state,
            "redirect_url": pay_resp.redirect_url,
            "status": "PENDING"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/shop-payment-status/{merchant_order_id}")
async def get_shop_payment_status(merchant_order_id: str, db: Session = Depends(get_db)):
    """Get shop payment status for a specific transaction."""
    transaction = db.query(PaymentTransaction).filter(
        PaymentTransaction.merchant_order_id == merchant_order_id
    ).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return {
        "merchant_order_id": merchant_order_id,
        "user_id": transaction.user_id,
        "shop_id": None,  # Not stored directly, but can be inferred from gift_name if needed
        "gift_name": transaction.gift_name,
        "diamond_amount": transaction.diamond_amount,
        "amount_paid": transaction.amount_paid,
        "status": transaction.status,
        "created_at": transaction.created_at,
        "updated_at": transaction.updated_at
    }

@app.get("/shop-payment-history")
async def get_shop_payment_history(
    user_id: Optional[int] = Query(None, description="Filter by user ID"),
    status: Optional[str] = Query(None, description="Filter by status (PENDING, SUCCESS, FAILED)"),
    db: Session = Depends(get_db)
):
    """Get shop payment transaction history with optional filtering."""
    query = db.query(PaymentTransaction).filter(PaymentTransaction.gift_name.like("Shop:%"))
    if user_id is not None:
        query = query.filter(PaymentTransaction.user_id == user_id)
    if status is not None:
        query = query.filter(PaymentTransaction.status == status.upper())
    transactions = query.order_by(PaymentTransaction.created_at.desc()).all()
    result = []
    for t in transactions:
        result.append({
            "merchant_order_id": t.merchant_order_id,
            "user_id": t.user_id,
            "gift_name": t.gift_name,
            "diamond_amount": t.diamond_amount,
            "amount_paid": t.amount_paid,
            "status": t.status,
            "created_at": t.created_at,
            "updated_at": t.updated_at
        })
    return {
        "total_transactions": len(result),
        "transactions": result
    }

@app.post("/update-shop-payment-status/{merchant_order_id}")
async def update_shop_payment_status(merchant_order_id: str, status: str, db: Session = Depends(get_db)):
    """Update shop payment status (for webhook or manual updates)."""
    transaction = db.query(PaymentTransaction).filter(
        PaymentTransaction.merchant_order_id == merchant_order_id
    ).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    transaction.status = status.upper()
    transaction.updated_at = get_delayed_datetime()
    db.commit()
    return {
        "merchant_order_id": merchant_order_id,
        "status": status.upper(),
        "updated_at": transaction.updated_at
    }

@app.delete("/shop-payment/{merchant_order_id}")
async def delete_shop_payment(merchant_order_id: str, db: Session = Depends(get_db)):
    """Delete a shop payment transaction by merchant_order_id."""
    transaction = db.query(PaymentTransaction).filter(
        PaymentTransaction.merchant_order_id == merchant_order_id
    ).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    db.delete(transaction)
    db.commit()
    return {"message": f"Shop payment transaction {merchant_order_id} deleted."}
    

@app.get("/diamond-history/{user_id}")
async def get_diamond_history_by_user(user_id: int, db: Session = Depends(get_db)):
    """Get diamond history for a specific user."""
    history = db.query(DiamondHistory).filter(DiamondHistory.user_id == user_id).order_by(DiamondHistory.datetime.desc()).all()
    return [
        {
            "id": h.id,
            "user_id": h.user_id,
            "datetime": h.datetime,
            "amount": h.amount,
            "status": h.status
        }
        for h in history
    ]

@app.get("/diamond-history-all")
async def get_all_diamond_history(db: Session = Depends(get_db)):
    """Get all diamond history records."""
    history = db.query(DiamondHistory).order_by(DiamondHistory.datetime.desc()).all()
    return [
        {
            "id": h.id,
            "user_id": h.user_id,
            "datetime": h.datetime,
            "amount": h.amount,
            "status": h.status
        }
        for h in history
    ]

@app.get("/diamond-history-merged")
async def get_diamond_history_merged(
    user_id: Optional[int] = Query(None, description="Optional user ID to filter"),
    db: Session = Depends(get_db)
):
    """Get diamond history with nested structure - combines user-specific and all history."""
    # Get all diamond history
    all_history = db.query(DiamondHistory).order_by(DiamondHistory.datetime.desc()).all()
    
    # Get user-specific history if user_id is provided
    user_history = []
    if user_id:
        user_history = db.query(DiamondHistory).filter(
            DiamondHistory.user_id == user_id
        ).order_by(DiamondHistory.datetime.desc()).all()
    
    # Convert to response format
    all_history_data = [
        {
            "id": h.id,
            "user_id": h.user_id,
            "datetime": h.datetime,
            "amount": h.amount,
            "status": h.status
        }
        for h in all_history
    ]
    
    user_history_data = [
        {
            "id": h.id,
            "user_id": h.user_id,
            "datetime": h.datetime,
            "amount": h.amount,
            "status": h.status
        }
        for h in user_history
    ]
    
    return {
        "summary": {
            "total_records": len(all_history_data),
            "user_specific_records": len(user_history_data) if user_id else 0,
            "requested_user_id": user_id
        },
        "all_diamond_history": all_history_data,
        "user_diamond_history": user_history_data if user_id else [],
        "user_summary": {
            "total_credited": sum(h.amount for h in user_history if h.status == "credited"),
            "total_debited": sum(abs(h.amount) for h in user_history if h.status == "debit"),
            "total_bought": sum(h.amount for h in user_history if h.status == "bought")
        } if user_id else None
    }

@app.get("/user-diamond-history")
async def get_user_diamond_history_by_period(
    period: str = Query(..., description="Time period: daily, weekly, or monthly"),
    db: Session = Depends(get_db)
):
    """Get user diamond history filtered by time period (daily, weekly, monthly)."""
    # Calculate the start date based on period
    now = get_delayed_datetime()
    if period.lower() == "daily":
        start_date = now.replace(hour=0, minute=0, second=0, microsecond=0)
    elif period.lower() == "weekly":
        # Get start of current week (Monday)
        days_since_monday = now.weekday()
        start_date = now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=days_since_monday)
    elif period.lower() == "monthly":
        # Get start of current month
        start_date = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    else:
        raise HTTPException(status_code=400, detail="Period must be 'daily', 'weekly', or 'monthly'")
    
    # Get all users
    users = db.query(User).all()
    result = []
    
    for user in users:
        # Get diamond history for this user within the specified period
        diamond_history = db.query(DiamondHistory).filter(
            DiamondHistory.user_id == user.id,
            DiamondHistory.datetime >= start_date
        ).order_by(DiamondHistory.datetime.desc()).all()
        
        # Calculate summary for this period
        total_credited = sum(h.amount for h in diamond_history if h.status == "credited")
        total_debited = sum(abs(h.amount) for h in diamond_history if h.status == "debit")
        total_bought = sum(h.amount for h in diamond_history if h.status == "bought")
        
        # Calculate daily, weekly, and monthly totals
        now = get_delayed_datetime()
        
        # Daily totals (from start of today)
        daily_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        daily_history = db.query(DiamondHistory).filter(
            DiamondHistory.user_id == user.id,
            DiamondHistory.datetime >= daily_start
        ).all()
        daily_credited = sum(h.amount for h in daily_history if h.status == "credited")
        daily_debited = sum(abs(h.amount) for h in daily_history if h.status == "debit")
        daily_bought = sum(h.amount for h in daily_history if h.status == "bought")
        
        # Weekly totals (from start of current week - Monday)
        days_since_monday = now.weekday()
        weekly_start = now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=days_since_monday)
        weekly_history = db.query(DiamondHistory).filter(
            DiamondHistory.user_id == user.id,
            DiamondHistory.datetime >= weekly_start
        ).all()
        weekly_credited = sum(h.amount for h in weekly_history if h.status == "credited")
        weekly_debited = sum(abs(h.amount) for h in weekly_history if h.status == "debit")
        weekly_bought = sum(h.amount for h in weekly_history if h.status == "bought")
        
        # Monthly totals (from start of current month)
        monthly_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        monthly_history = db.query(DiamondHistory).filter(
            DiamondHistory.user_id == user.id,
            DiamondHistory.datetime >= monthly_start
        ).all()
        monthly_credited = sum(h.amount for h in monthly_history if h.status == "credited")
        monthly_debited = sum(abs(h.amount) for h in monthly_history if h.status == "debit")
        monthly_bought = sum(h.amount for h in monthly_history if h.status == "bought")
        
        result.append({
            "user": {
                "id": user.id,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "username": user.username,
                "phone_number": user.phone_number,
                "email": user.email,
                "profile_pic": user.profile_pic,
                "diamonds": user.diamonds,
                "balance": user.balance,
                "is_online": user.is_online,
                "created_at": user.created_at
            },
            "diamond_history": [
                {
                    "id": h.id,
                    "datetime": h.datetime,
                    "amount": h.amount,
                    "status": h.status
                }
                for h in diamond_history
            ],
            "summary": {
                "total_credited": total_credited,
                "total_debited": total_debited,
                "total_bought": total_bought,
                "total_transactions": len(diamond_history),
                "daily": {
                    "credited": daily_credited,
                    "debited": daily_debited,
                    "bought": daily_bought
                },
                "weekly": {
                    "credited": weekly_credited,
                    "debited": weekly_debited,
                    "bought": weekly_bought
                },
                "monthly": {
                    "credited": monthly_credited,
                    "debited": monthly_debited,
                    "bought": monthly_bought
                }
            }
        })
    
    return {
        "total_users": len(result),
        "users": result
    }

@app.get("/single-url", response_model=SingleURLResponse)
async def get_single_url(db: Session = Depends(get_db)):
    url_obj = db.query(SingleURL).order_by(SingleURL.created_at.desc()).first()
    if not url_obj:
        raise HTTPException(status_code=404, detail="URL not found")
    return SingleURLResponse(url=url_obj.url, created_at=url_obj.created_at)

@app.put("/single-url", response_model=SingleURLResponse)
async def update_single_url(data: SingleURLUpdate, db: Session = Depends(get_db)):
    url_obj = db.query(SingleURL).order_by(SingleURL.created_at.desc()).first()
    if url_obj:
        url_obj.url = data.url
        db.commit()
        db.refresh(url_obj)
    else:
        url_obj = SingleURL(url=data.url)
        db.add(url_obj)
        db.commit()
        db.refresh(url_obj)
    return SingleURLResponse(url=url_obj.url, created_at=url_obj.created_at)

@app.get("/users/{user_id}/relations")
async def get_user_relations(user_id: int, db: Session = Depends(get_db)):
    """Get the list of user IDs whom the user has blocked and is following."""
    # Blocked users
    blocked = db.query(user_blocked.c.blocked_user_id).filter(user_blocked.c.user_id == user_id).all()
    blocked_ids = [row[0] for row in blocked]
    # Following users
    following = db.query(user_following.c.following_id).filter(user_following.c.follower_id == user_id).all()
    following_ids = [row[0] for row in following]
    return {
        "user_id": user_id,
        "blocked": blocked_ids,
        "following": following_ids
    }

@app.post("/helpsupportapi", response_model=HelpSupportResponse)
async def create_help_support(data: HelpSupportCreate, db: Session = Depends(get_db)):
    hs = HelpSupport(content=data.content)
    db.add(hs)
    db.commit()
    db.refresh(hs)
    return HelpSupportResponse(id=hs.id, content=hs.content, created_at=hs.created_at)

@app.get("/helpsupportapi", response_model=list[HelpSupportResponse])
async def get_all_help_support(db: Session = Depends(get_db)):
    hs_list = db.query(HelpSupport).order_by(HelpSupport.created_at.desc()).all()
    return [HelpSupportResponse(id=hs.id, content=hs.content, created_at=hs.created_at) for hs in hs_list]

@app.get("/helpsupportapi/{hs_id}", response_model=HelpSupportResponse)
async def get_help_support_by_id(hs_id: int, db: Session = Depends(get_db)):
    hs = db.query(HelpSupport).filter(HelpSupport.id == hs_id).first()
    if not hs:
        raise HTTPException(status_code=404, detail="HelpSupport not found")
    return HelpSupportResponse(id=hs.id, content=hs.content, created_at=hs.created_at)

@app.put("/helpsupportapi/{hs_id}", response_model=HelpSupportResponse)
async def update_help_support(hs_id: int, data: HelpSupportUpdate, db: Session = Depends(get_db)):
    hs = db.query(HelpSupport).filter(HelpSupport.id == hs_id).first()
    if not hs:
        raise HTTPException(status_code=404, detail="HelpSupport not found")
    hs.content = data.content
    db.commit()
    db.refresh(hs)
    return HelpSupportResponse(id=hs.id, content=hs.content, created_at=hs.created_at)

@app.delete("/helpsupportapi/{hs_id}", response_model=dict)
async def delete_help_support(hs_id: int, db: Session = Depends(get_db)):
    hs = db.query(HelpSupport).filter(HelpSupport.id == hs_id).first()
    if not hs:
        raise HTTPException(status_code=404, detail="HelpSupport not found")
    db.delete(hs)
    db.commit()
    return {"message": f"HelpSupport {hs_id} deleted"}

@app.get("/payment-details")
async def get_all_payment_details(db: Session = Depends(get_db)):
    """Get all payment transactions (no auth required)."""
    transactions = db.query(PaymentTransaction).order_by(PaymentTransaction.created_at.desc()).all()
    return [
        {
            "merchant_order_id": t.merchant_order_id,
            "user_id": t.user_id,
            "gift_id": t.gift_id,
            "gift_name": t.gift_name,
            "diamond_amount": t.diamond_amount,
            "amount_paid": t.amount_paid,
            "status": t.status,
            "created_at": t.created_at,
            "updated_at": t.updated_at
        }
        for t in transactions
    ]

@app.get("/payment-details/{user_id}")
async def get_payment_details_by_user(user_id: int, db: Session = Depends(get_db)):
    """Get all payment transactions for a specific user (no auth required)."""
    transactions = db.query(PaymentTransaction).filter(PaymentTransaction.user_id == user_id).order_by(PaymentTransaction.created_at.desc()).all()
    return [
        {
            "merchant_order_id": t.merchant_order_id,
            "user_id": t.user_id,
            "gift_id": t.gift_id,
            "gift_name": t.gift_name,
            "diamond_amount": t.diamond_amount,
            "amount_paid": t.amount_paid,
            "status": t.status,
            "created_at": t.created_at,
            "updated_at": t.updated_at
        }
        for t in transactions
    ]

@app.get("/bank-details")
async def get_all_bank_details(db: Session = Depends(get_db)):
    """Get all users' bank details (no auth required)."""
    users = db.query(User).all()
    return [
        {
            "user_id": user.id,
            "upi_id": user.upi_id,
            "bank_account_name": user.bank_account_name,
            "bank_account_number": user.bank_account_number,
            "bank_ifsc": user.bank_ifsc
        }
        for user in users
    ]

@app.get("/bank-details/{user_id}")
async def get_bank_details_by_user(user_id: int, db: Session = Depends(get_db)):
    """Get bank details for a specific user (no auth required)."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "user_id": user.id,
        "upi_id": user.upi_id,
        "bank_account_name": user.bank_account_name,
        "bank_account_number": user.bank_account_number,
        "bank_ifsc": user.bank_ifsc
    }

@app.post("/withdraw-diamond", response_model=WithdrawDiamondResponse)
async def create_withdraw_diamond(data: WithdrawDiamondCreate, db: Session = Depends(get_db)):
    wd = WithdrawDiamond(**data.dict())
    db.add(wd)
    db.commit()
    db.refresh(wd)
    return WithdrawDiamondResponse(
        id=wd.id,
        user_id=wd.user_id,
        diamond_count=wd.diamond_count,
        status=wd.status,
        created_at=wd.created_at
    )

@app.get("/withdraw-diamond", response_model=list[WithdrawDiamondResponse])
async def get_all_withdraw_diamond(db: Session = Depends(get_db)):
    wds = db.query(WithdrawDiamond).order_by(WithdrawDiamond.created_at.desc()).all()
    return [WithdrawDiamondResponse(
        id=wd.id,
        user_id=wd.user_id,
        diamond_count=wd.diamond_count,
        status=wd.status,
        created_at=wd.created_at
    ) for wd in wds]

@app.get("/withdraw-diamond/{wd_id}", response_model=WithdrawDiamondResponse)
async def get_withdraw_diamond_by_id(wd_id: int, db: Session = Depends(get_db)):
    wd = db.query(WithdrawDiamond).filter(WithdrawDiamond.id == wd_id).first()
    if not wd:
        raise HTTPException(status_code=404, detail="WithdrawDiamond not found")
    return WithdrawDiamondResponse(
        id=wd.id,
        user_id=wd.user_id,
        diamond_count=wd.diamond_count,
        status=wd.status,
        created_at=wd.created_at
    )

@app.put("/withdraw-diamond/{wd_id}", response_model=WithdrawDiamondResponse)
async def update_withdraw_diamond(wd_id: int, data: WithdrawDiamondUpdate, db: Session = Depends(get_db)):
    wd = db.query(WithdrawDiamond).filter(WithdrawDiamond.id == wd_id).first()
    if not wd:
        raise HTTPException(status_code=404, detail="WithdrawDiamond not found")
    previous_status = wd.status
    for field, value in data.dict(exclude_unset=True).items():
        setattr(wd, field, value)
    db.commit()
    db.refresh(wd)
    # Add diamond history and deduct diamonds if status changed to COMPLETED or Approved
    if (
        (wd.status and wd.status.upper() in ["COMPLETED", "APPROVED"]) and
        (previous_status is None or previous_status.upper() not in ["COMPLETED", "APPROVED"])
    ):
        # Deduct diamonds from user
        user = db.query(User).filter(User.id == wd.user_id).first()
        if user:
            user.diamonds = max(0, user.diamonds - wd.diamond_count)
            # Update user wallet if exists
            wallet = db.query(UserWallet).filter(UserWallet.user_id == wd.user_id).first()
            if wallet:
                wallet.diamonds = user.diamonds
                wallet.last_updated = get_delayed_datetime()
        # Add diamond history (negative amount for withdrawal)
        history = DiamondHistory(
            user_id=wd.user_id,
            amount=-wd.diamond_count,
            status="withdrawn"
        )
        db.add(history)
        db.commit()
    return WithdrawDiamondResponse(
        id=wd.id,
        user_id=wd.user_id,
        diamond_count=wd.diamond_count,
        status=wd.status,
        created_at=wd.created_at
    )

@app.delete("/withdraw-diamond/{wd_id}", response_model=dict)
async def delete_withdraw_diamond(wd_id: int, db: Session = Depends(get_db)):
    wd = db.query(WithdrawDiamond).filter(WithdrawDiamond.id == wd_id).first()
    if not wd:
        raise HTTPException(status_code=404, detail="WithdrawDiamond not found")
    db.delete(wd)
    db.commit()
    return {"message": f"WithdrawDiamond {wd_id} deleted"}

@app.get("/withdraw-diamond-info", response_model=WithdrawDiamondInfoResponse)
async def get_withdraw_diamond_info(db: Session = Depends(get_db)):
    info = db.query(WithdrawDiamondInfo).order_by(WithdrawDiamondInfo.created_at.desc()).first()
    if not info:
        raise HTTPException(status_code=404, detail="WithdrawDiamondInfo not found")
    return WithdrawDiamondInfoResponse(
        minimum_diamond=info.minimum_diamond,
        conversion_rate=info.conversion_rate,
        created_at=info.created_at
    )

@app.put("/withdraw-diamond-info", response_model=WithdrawDiamondInfoResponse)
async def update_withdraw_diamond_info(data: WithdrawDiamondInfoUpdate, db: Session = Depends(get_db)):
    info = db.query(WithdrawDiamondInfo).order_by(WithdrawDiamondInfo.created_at.desc()).first()
    if not info:
        info = WithdrawDiamondInfo(
            minimum_diamond=data.minimum_diamond or 0,
            conversion_rate=data.conversion_rate or 0.0
        )
        db.add(info)
        db.commit()
        db.refresh(info)
    else:
        if data.minimum_diamond is not None:
            info.minimum_diamond = data.minimum_diamond
        if data.conversion_rate is not None:
            info.conversion_rate = data.conversion_rate
        db.commit()
        db.refresh(info)
    return WithdrawDiamondInfoResponse(
        minimum_diamond=info.minimum_diamond,
        conversion_rate=info.conversion_rate,
        created_at=info.created_at
    )

# --- STAR API ---
@app.get("/stars/{user_id}")
async def get_user_stars(user_id: int, db: Session = Depends(get_db)):
    star = db.query(Star).filter(Star.user_id == user_id).first()
    if not star:
        return {"user_id": user_id, "total_stars": 0}
    return {"user_id": user_id, "total_stars": star.total_stars}

@app.get("/star-history/{user_id}")
async def get_star_history(user_id: int, db: Session = Depends(get_db)):
    history = db.query(StarHistory).filter(StarHistory.user_id == user_id).order_by(StarHistory.datetime.desc()).all()
    return [
        {
            "id": h.id,
            "user_id": h.user_id,
            "datetime": h.datetime,
            "amount": h.amount,
            "status": h.status
        }
        for h in history
    ]

@app.post("/auto-credit-diamonds/{merchant_order_id}")
async def auto_credit_diamonds(merchant_order_id: str, db: Session = Depends(get_db)):
    """Polls /order-status and credits diamonds if completed."""
    max_attempts = 240  # 20 minutes at 5s interval
    interval = 5
    credited = False
    for attempt in range(max_attempts):
        # Call the local /order-status endpoint
        async with httpx.AsyncClient() as client:
            try:
                resp = await client.post(
                    "http://localhost:8000/order-status",
                    json={"merchant_order_id": merchant_order_id},
                    timeout=10
                )
                if resp.status_code == 200:
                    data = resp.json()
                    if data.get("state") == "COMPLETED":
                        # Check if already credited
                        transaction = db.query(PaymentTransaction).filter(PaymentTransaction.merchant_order_id == merchant_order_id).first()
                        if transaction and transaction.status != "SUCCESS":
                            transaction.status = "SUCCESS"
                            transaction.updated_at = get_delayed_datetime()
                            user = db.query(User).filter(User.id == transaction.user_id).first()
                            if user:
                                user.diamonds += transaction.diamond_amount
                                # Update user wallet
                                wallet = db.query(UserWallet).filter(UserWallet.user_id == user.id).first()
                                if wallet:
                                    wallet.diamonds = user.diamonds
                                    wallet.last_updated = get_delayed_datetime()
                                # Add to diamond history
                                history = DiamondHistory(
                                    user_id=user.id,
                                    amount=transaction.diamond_amount,
                                    status="bought"
                                )
                                db.add(history)
                            db.commit()
                            credited = True
                        return {"status": "CREDITED", "message": "Diamonds credited to user."}
            except Exception as e:
                pass  # Ignore and retry
        await asyncio.sleep(interval)
    return {"status": "TIMEOUT", "message": "Order not completed in 20 minutes."}

@app.get("/user/minimal")
async def get_minimal_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return [
        {
            "id": user.id,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "username": user.username
        }
        for user in users
    ]

@app.delete("/users/{user_id}")
async def delete_user(user_id: int, db: Session = Depends(get_db)):
    # Check if user exists
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Delete the user
    db.delete(user)
    db.commit()
    
    return {"message": "User deleted successfully", "user_id": user_id}

@app.get("/users/{user_id}/following-ids")
async def get_user_following_ids(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    following = db.query(user_following.c.following_id).filter(user_following.c.follower_id == user_id).all()
    following_ids = [row[0] for row in following]
    return {
        "user_id": user_id,
        "following_count": len(following_ids),
        "following_ids": following_ids
    }

@app.get("/users/{user_id}/relations-full")
async def get_user_relations_full(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    # Followers: users who follow this user
    followers = db.query(user_following.c.follower_id).filter(user_following.c.following_id == user_id).all()
    followers_ids = [row[0] for row in followers]
    # Following: users this user is following
    following = db.query(user_following.c.following_id).filter(user_following.c.follower_id == user_id).all()
    following_ids = [row[0] for row in following]
    return {
        "user_id": user_id,
        "followers_count": len(followers_ids),
        "followers_ids": followers_ids,
        "following_count": len(following_ids),
        "following_ids": following_ids
    }

@app.post("/users/{follower_id}/follow/{following_id}")
async def force_follow_user(follower_id: int, following_id: int, db: Session = Depends(get_db)):
    if follower_id == following_id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself")
    follower = db.query(User).filter(User.id == follower_id).first()
    following = db.query(User).filter(User.id == following_id).first()
    if not follower or not following:
        raise HTTPException(status_code=404, detail="User not found")
    # Check if already following
    existing_follow = db.query(user_following).filter(
        user_following.c.follower_id == follower_id,
        user_following.c.following_id == following_id
    ).first()
    if existing_follow:
        raise HTTPException(status_code=400, detail="Already following this user")
    # Add to following relationship
    db.execute(
        user_following.insert().values(
            follower_id=follower_id,
            following_id=following_id
        )
    )
    db.commit()
    return {"message": f"User {follower_id} is now following user {following_id}"}

@app.post("/admin/send-gift")
async def admin_send_gift(
    data: AdminSendGiftRequest,
    db: Session = Depends(get_db)
):
    sender = db.query(User).filter(User.id == data.sender_id).first()
    if not sender:
        raise HTTPException(status_code=404, detail="Sender not found")
    receiver = db.query(User).filter(User.id == data.receiver_id).first()
    if not receiver:
        raise HTTPException(status_code=404, detail="Receiver not found")
    if data.receiver_id == data.sender_id:
        raise HTTPException(status_code=400, detail="Cannot send gift to yourself")
    gift = db.query(Gift).filter(Gift.id == data.gift_id).first()
    if not gift:
        raise HTTPException(status_code=404, detail="Gift not found")
    if sender.diamonds < gift.diamond_amount:
        return {
            "error": "Insufficient diamonds",
            "required_diamonds": gift.diamond_amount,
            "current_diamonds": sender.diamonds,
            "shortfall": gift.diamond_amount - sender.diamonds,
            "suggestion": "Purchase more diamonds to send this gift",
            "gift_name": gift.name,
            "gift_cost": gift.diamond_amount
        }
    sender.diamonds -= gift.diamond_amount
    sender_wallet = get_or_create_user_wallet(sender.id, db)
    sender_wallet.diamonds = sender.diamonds
    sender_wallet.last_updated = get_delayed_datetime()
    gift_transaction = GiftTransaction(
        sender_id=sender.id,
        receiver_id=receiver.id,
        gift_id=gift.id,
        diamond_amount=gift.diamond_amount,
        live_stream_id=data.live_stream_id,
        live_stream_type=data.live_stream_type
    )
    sender_history = DiamondHistory(
        user_id=sender.id,
        amount=-gift.diamond_amount,
        status="debit"
    )
    db.add(gift_transaction)
    db.add(sender_history)
    db.commit()
    star_amount = gift.diamond_amount * 3
    star = db.query(Star).filter(Star.user_id == receiver.id).first()
    if not star:
        star = Star(user_id=receiver.id, total_stars=0)
        db.add(star)
        db.flush()
    star.total_stars += star_amount
    star.last_updated = get_delayed_datetime()
    star_history = StarHistory(
        user_id=receiver.id,
        amount=star_amount,
        status="credited"
    )
    db.add(star_history)
    db.commit()
    return {
        "message": f"Gift sent successfully",
        "gift_name": gift.name,
        "diamond_amount": gift.diamond_amount,
        "sender_diamonds": sender.diamonds,
        "receiver_stars": star.total_stars,
        "stars_credited": star_amount
    }

@app.get("/user-star-history")
async def get_user_star_history_by_period(
    period: str = Query(..., description="Time period: daily, weekly, or monthly"),
    db: Session = Depends(get_db)
):
    """Get user star history filtered by time period (daily, weekly, monthly)."""
    # Calculate the start date based on period
    now = get_delayed_datetime()
    if period.lower() == "daily":
        start_date = now.replace(hour=0, minute=0, second=0, microsecond=0)
    elif period.lower() == "weekly":
        days_since_monday = now.weekday()
        start_date = now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=days_since_monday)
    elif period.lower() == "monthly":
        start_date = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    else:
        raise HTTPException(status_code=400, detail="Period must be 'daily', 'weekly', or 'monthly'")
    users = db.query(User).all()
    result = []
    for user in users:
        star_history = db.query(StarHistory).filter(
            StarHistory.user_id == user.id,
            StarHistory.datetime >= start_date
        ).order_by(StarHistory.datetime.desc()).all()
        total_credited = sum(h.amount for h in star_history if h.status == "credited")
        total_debited = sum(abs(h.amount) for h in star_history if h.status == "debit")
        # Daily totals
        daily_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        daily_history = db.query(StarHistory).filter(
            StarHistory.user_id == user.id,
            StarHistory.datetime >= daily_start
        ).all()
        daily_credited = sum(h.amount for h in daily_history if h.status == "credited")
        daily_debited = sum(abs(h.amount) for h in daily_history if h.status == "debit")
        # Weekly totals
        days_since_monday = now.weekday()
        weekly_start = now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=days_since_monday)
        weekly_history = db.query(StarHistory).filter(
            StarHistory.user_id == user.id,
            StarHistory.datetime >= weekly_start
        ).all()
        weekly_credited = sum(h.amount for h in weekly_history if h.status == "credited")
        weekly_debited = sum(abs(h.amount) for h in weekly_history if h.status == "debit")
        # Monthly totals
        monthly_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        monthly_history = db.query(StarHistory).filter(
            StarHistory.user_id == user.id,
            StarHistory.datetime >= monthly_start
        ).all()
        monthly_credited = sum(h.amount for h in monthly_history if h.status == "credited")
        monthly_debited = sum(abs(h.amount) for h in monthly_history if h.status == "debit")
        result.append({
            "user": {
                "id": user.id,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "username": user.username,
                "phone_number": user.phone_number,
                "email": user.email,
                "profile_pic": user.profile_pic,
                "diamonds": user.diamonds,
                "balance": user.balance,
                "is_online": user.is_online,
                "created_at": user.created_at
            },
            "star_history": [
                {
                    "id": h.id,
                    "datetime": h.datetime,
                    "amount": h.amount,
                    "status": h.status
                }
                for h in star_history
            ],
            "summary": {
                "total_credited": total_credited,
                "total_debited": total_debited,
                "total_transactions": len(star_history),
                "daily": {
                    "credited": daily_credited,
                    "debited": daily_debited
                },
                "weekly": {
                    "credited": weekly_credited,
                    "debited": weekly_debited
                },
                "monthly": {
                    "credited": monthly_credited,
                    "debited": monthly_debited
                }
            }
        })
    return {
        "total_users": len(result),
        "users": result
    }

@app.post("/stars/add")
async def add_stars(
    amount: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Get or create Star record for current user
    star = db.query(Star).filter(Star.user_id == current_user.id).first()
    if not star:
        star = Star(user_id=current_user.id, total_stars=0)
        db.add(star)
        db.flush()
    star.total_stars += amount
    star.last_updated = get_delayed_datetime()
    # Add to history
    history = StarHistory(
        user_id=current_user.id,
        amount=amount,
        status="credited"
    )
    db.add(history)
    db.commit()
    return {"message": f"Added {amount} stars", "total_stars": star.total_stars}

@app.get("/stars/history")
async def get_star_history_current_user(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    history = db.query(StarHistory).filter(StarHistory.user_id == current_user.id).order_by(StarHistory.datetime.desc()).all()
    return history

@app.get("/star-history/{user_id}")
async def get_star_history_by_user(user_id: int, db: Session = Depends(get_db)):
    """Get star history for a specific user."""
    history = db.query(StarHistory).filter(StarHistory.user_id == user_id).order_by(StarHistory.datetime.desc()).all()
    return [
        {
            "id": h.id,
            "user_id": h.user_id,
            "datetime": h.datetime,
            "amount": h.amount,
            "status": h.status
        }
        for h in history
    ]

@app.get("/star-history-all")
async def get_all_star_history(db: Session = Depends(get_db)):
    """Get all star history records."""
    history = db.query(StarHistory).order_by(StarHistory.datetime.desc()).all()
    return [
        {
            "id": h.id,
            "user_id": h.user_id,
            "datetime": h.datetime,
            "amount": h.amount,
            "status": h.status
        }
        for h in history
    ]

@app.get("/star-history-merged")
async def get_star_history_merged(
    user_id: Optional[int] = Query(None, description="Optional user ID to filter"),
    db: Session = Depends(get_db)
):
    """Get star history with nested structure - combines user-specific and all history."""
    all_history = db.query(StarHistory).order_by(StarHistory.datetime.desc()).all()
    user_history = []
    if user_id:
        user_history = db.query(StarHistory).filter(
            StarHistory.user_id == user_id
        ).order_by(StarHistory.datetime.desc()).all()
    all_history_data = [
        {
            "id": h.id,
            "user_id": h.user_id,
            "datetime": h.datetime,
            "amount": h.amount,
            "status": h.status
        }
        for h in all_history
    ]
    user_history_data = [
        {
            "id": h.id,
            "user_id": h.user_id,
            "datetime": h.datetime,
            "amount": h.amount,
            "status": h.status
        }
        for h in user_history
    ]
    return {
        "summary": {
            "total_records": len(all_history_data),
            "user_specific_records": len(user_history_data) if user_id else 0,
            "requested_user_id": user_id
        },
        "all_star_history": all_history_data,
        "user_star_history": user_history_data if user_id else [],
        "user_summary": {
            "total_credited": sum(h.amount for h in user_history if h.status == "credited"),
            "total_debited": sum(abs(h.amount) for h in user_history if h.status == "debit")
        } if user_id else None
    }

@app.post("/withdraw-star", response_model=WithdrawStarResponse)
async def create_withdraw_star(data: WithdrawStarCreate, db: Session = Depends(get_db)):
    ws = WithdrawStar(**data.dict())
    db.add(ws)
    db.commit()
    db.refresh(ws)
    return WithdrawStarResponse(
        id=ws.id,
        user_id=ws.user_id,
        star_count=ws.star_count,
        status=ws.status,
        created_at=ws.created_at
    )

@app.get("/withdraw-star", response_model=list[WithdrawStarResponse])
async def get_all_withdraw_star(db: Session = Depends(get_db)):
    wss = db.query(WithdrawStar).order_by(WithdrawStar.created_at.desc()).all()
    return [WithdrawStarResponse(
        id=ws.id,
        user_id=ws.user_id,
        star_count=ws.star_count,
        status=ws.status,
        created_at=ws.created_at
    ) for ws in wss]

@app.get("/withdraw-star/{ws_id}", response_model=WithdrawStarResponse)
async def get_withdraw_star_by_id(ws_id: int, db: Session = Depends(get_db)):
    ws = db.query(WithdrawStar).filter(WithdrawStar.id == ws_id).first()
    if not ws:
        raise HTTPException(status_code=404, detail="WithdrawStar not found")
    return WithdrawStarResponse(
        id=ws.id,
        user_id=ws.user_id,
        star_count=ws.star_count,
        status=ws.status,
        created_at=ws.created_at
    )

@app.put("/withdraw-star/{ws_id}", response_model=WithdrawStarResponse)
async def update_withdraw_star(ws_id: int, data: WithdrawStarUpdate, db: Session = Depends(get_db)):
    ws = db.query(WithdrawStar).filter(WithdrawStar.id == ws_id).first()
    if not ws:
        raise HTTPException(status_code=404, detail="WithdrawStar not found")
    previous_status = ws.status
    for field, value in data.dict(exclude_unset=True).items():
        setattr(ws, field, value)
    db.commit()
    db.refresh(ws)
    # Add star history and deduct stars if status changed to COMPLETED or Approved
    if (
        (ws.status and ws.status.upper() in ["COMPLETED", "APPROVED"]) and
        (previous_status is None or previous_status.upper() not in ["COMPLETED", "APPROVED"])
    ):
        # Deduct stars from user
        star = db.query(Star).filter(Star.user_id == ws.user_id).first()
        if star:
            star.total_stars = max(0, star.total_stars - ws.star_count)
            star.last_updated = get_delayed_datetime()
        # Add star history (negative amount for withdrawal)
        history = StarHistory(
            user_id=ws.user_id,
            amount=-ws.star_count,
            status="withdrawn"
        )
        db.add(history)
        db.commit()
    return WithdrawStarResponse(
        id=ws.id,
        user_id=ws.user_id,
        star_count=ws.star_count,
        status=ws.status,
        created_at=ws.created_at
    )

@app.delete("/withdraw-star/{ws_id}", response_model=dict)
async def delete_withdraw_star(ws_id: int, db: Session = Depends(get_db)):
    ws = db.query(WithdrawStar).filter(WithdrawStar.id == ws_id).first()
    if not ws:
        raise HTTPException(status_code=404, detail="WithdrawStar not found")
    db.delete(ws)
    db.commit()
    return {"message": f"WithdrawStar {ws_id} deleted"}

@app.get("/withdraw-star-info", response_model=WithdrawStarInfoResponse)
async def get_withdraw_star_info(db: Session = Depends(get_db)):
    info = db.query(WithdrawStarInfo).order_by(WithdrawStarInfo.created_at.desc()).first()
    if not info:
        raise HTTPException(status_code=404, detail="WithdrawStarInfo not found")
    return WithdrawStarInfoResponse(
        minimum_star=info.minimum_star,
        conversion_rate=info.conversion_rate,
        created_at=info.created_at
    )

@app.put("/withdraw-star-info", response_model=WithdrawStarInfoResponse)
async def update_withdraw_star_info(data: WithdrawStarInfoUpdate, db: Session = Depends(get_db)):
    info = db.query(WithdrawStarInfo).order_by(WithdrawStarInfo.created_at.desc()).first()
    if not info:
        info = WithdrawStarInfo(
            minimum_star=data.minimum_star or 0,
            conversion_rate=data.conversion_rate or 0.0
        )
        db.add(info)
        db.commit()
        db.refresh(info)
    else:
        if data.minimum_star is not None:
            info.minimum_star = data.minimum_star
        if data.conversion_rate is not None:
            info.conversion_rate = data.conversion_rate
        db.commit()
        db.refresh(info)
    return WithdrawStarInfoResponse(
        minimum_star=info.minimum_star,
        conversion_rate=info.conversion_rate,
        created_at=info.created_at
    )

# --- PK BATTLE ENDPOINTS ---
@app.post("/pk-battle/start")
async def start_pk_battle(data: PKBattleStart, db: Session = Depends(get_db)):
    pk = PKBattle(
        left_host_id=data.left_host_id,
        right_host_id=data.right_host_id,
        left_stream_id=data.left_stream_id,
        right_stream_id=data.right_stream_id,
        status="active"
    )
    db.add(pk)
    db.commit()
    db.refresh(pk)
    return {"pk_battle_id": pk.id, "status": "started"}

@app.post("/pk-battle/gift")
async def pk_battle_gift(data: PKGiftSend, db: Session = Depends(get_db)):
    pk = db.query(PKBattle).filter(PKBattle.id == data.pk_battle_id, PKBattle.status == "active").first()
    if not pk:
        raise HTTPException(status_code=404, detail="PK battle not found or not active")
    # Update score
    if data.receiver_id == pk.left_host_id:
        pk.left_score += data.amount
    elif data.receiver_id == pk.right_host_id:
        pk.right_score += data.amount
    else:
        raise HTTPException(status_code=400, detail="Receiver not in PK battle")
    # Log gift
    pk_gift = PKGift(
        pk_battle_id=pk.id,
        sender_id=data.sender_id,
        receiver_id=data.receiver_id,
        gift_id=data.gift_id,
        amount=data.amount
    )
    db.add(pk_gift)
    db.commit()
    return {"status": "score updated", "left_score": pk.left_score, "right_score": pk.right_score}

@app.post("/pk-battle/end")
async def end_pk_battle(data: PKBattleEnd, db: Session = Depends(get_db)):
    pk = db.query(PKBattle).filter(PKBattle.id == data.pk_battle_id, PKBattle.status == "active").first()
    if not pk:
        raise HTTPException(status_code=404, detail="PK battle not found or not active")
    pk.left_score = data.left_score
    pk.right_score = data.right_score
    pk.winner_id = data.winner_id
    pk.end_time = get_delayed_datetime()
    pk.status = "ended"
    db.commit()
    return {"status": "ended", "winner_id": pk.winner_id}

@app.get("/pk-battle/{pk_id}")
async def get_pk_battle(pk_id: int, db: Session = Depends(get_db)):
    pk = db.query(PKBattle).filter(PKBattle.id == pk_id).first()
    if not pk:
        raise HTTPException(status_code=404, detail="PK battle not found")
    return {
        "id": pk.id,
        "left_host_id": pk.left_host_id,
        "right_host_id": pk.right_host_id,
        "left_score": pk.left_score,
        "right_score": pk.right_score,
        "start_time": pk.start_time,
        "end_time": pk.end_time,
        "winner_id": pk.winner_id,
        "status": pk.status
    }

@app.get("/pk-battle/history")
async def pk_battle_history(user_id: Optional[int] = None, db: Session = Depends(get_db)):
    query = db.query(PKBattle)
    if user_id:
        query = query.filter((PKBattle.left_host_id == user_id) | (PKBattle.right_host_id == user_id))
    battles = query.order_by(PKBattle.start_time.desc()).all()
    return [
        {
            "id": pk.id,
            "left_host_id": pk.left_host_id,
            "right_host_id": pk.right_host_id,
            "left_score": pk.left_score,
            "right_score": pk.right_score,
            "start_time": pk.start_time,
            "end_time": pk.end_time,
            "winner_id": pk.winner_id,
            "status": pk.status
        }
        for pk in battles
    ]

PKBattle.__table__.create(bind=engine, checkfirst=True)
PKGift.__table__.create(bind=engine, checkfirst=True)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)