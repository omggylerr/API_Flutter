import random
import resend
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel

app = FastAPI()

# Allow frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Configuration ---
MONGO_DETAILS = "mongodb://127.0.0.1:27017"
client = AsyncIOMotorClient(MONGO_DETAILS)
db = client.user
user_collection = db.user

# Resend API Key
# resend.api_key = "re_NM4zfCWp_LzwRLyoWJtfaPigJeq9aWY22"
resend.api_key = "re_L4seHn7w_DYtgKDLSJEXrP2K2Qme4Hrad"

# In-memory OTP storage
otp_storage = {}

# --- Models ---
class LoginRequest(BaseModel):
    email: str
    password: str

class VerifyRequest(BaseModel):
    email: str
    otp_code: str

# --- Endpoints ---
@app.get("/")
async def root():
    return {
        "status": "Server is running",
        "documentation": "Visit http://127.0.0.1:8000/docs"
    }

@app.post("/login")
async def login(request: LoginRequest):

    # 1. Check user
    user = await user_collection.find_one({
        "email": request.email,
        "password": request.password
    })

    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # 2. Generate OTP
    otp = str(random.randint(100000, 999999))
    otp_storage[request.email] = otp

    # 3. Send OTP
    try:
        resend.Emails.send({
            "from": "onboarding@resend.dev",
            "to": request.email,
            "subject": "Your Login OTP",
            "html": f"<strong>Your OTP is: {otp}</strong>"
        })
    except Exception as e:
        print(f"Error sending email: {e}")
        print(f"DEBUG OTP for {request.email}: {otp}")

    return {"message": "OTP sent"}

@app.post("/verify-otp")
async def verify_otp(request: VerifyRequest):
    stored_otp = otp_storage.get(request.email)

    if stored_otp and stored_otp == request.otp_code:
        del otp_storage[request.email]
        return {"message": "Login Successful!", "status": "success"}

    raise HTTPException(status_code=400, detail="Invalid or expired OTP")