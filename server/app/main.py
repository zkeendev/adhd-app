import logging

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

import firebase_admin
from firebase_admin import credentials, auth, firestore

from .config import get_settings
from .models import ChatRequest, ChatResponse
from .services.chat_service import ChatService, get_chat_service

# --- Logging Configuration ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- App and Dependency Setup ---
settings = get_settings()

# --- Firebase Admin SDK Initialization ---
try:
    # Check if the app is already initialized to prevent errors during hot-reloading
    if not firebase_admin._apps:
        cred = credentials.Certificate(settings.firebase_service_account_key_path)
        firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialized successfully.")
    else:
        logger.info("Firebase Admin SDK already initialized.")
    
    db_client = firestore.client()

except Exception as e:
    logger.critical(f"Failed to initialize Firebase Admin SDK: {e}", exc_info=True)
    db_client = None # Ensure db_client is None if initialization fails

# --- FastAPI App Instance ---
app = FastAPI(
    title="ADHD App AI Backend",
    description="Handles AI responses for the ADHD companion app.",
    version="1.0.0",
)

# --- Authentication Dependency ---
http_bearer_scheme = HTTPBearer(
    scheme_name="Firebase ID Token",
    description="Authenticate using a Firebase ID Token provided as a Bearer token in the Authorization header.",
    bearerFormat="JWT"
)

async def get_current_user_uid(auth_creds: HTTPAuthorizationCredentials = Depends(http_bearer_scheme)) -> str:
    """
    Dependency to validate Firebase ID token and return the user's UID.
    """
    if not auth_creds or auth_creds.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication scheme. Expected 'Bearer'.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    token = auth_creds.credentials
    
    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token.get('uid')
        if not uid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="UID not found in token.",
                headers={"WWW-Authenticate": "Bearer error=\"invalid_token\""},
            )
        return uid
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase ID token has expired.",
            headers={"WWW-Authenticate": "Bearer error=\"invalid_token\", error_description=\"Token expired\""},
        )
    except auth.InvalidIdTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Firebase ID token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer error=\"invalid_token\""},
        )
    except Exception as e:
        logger.error(f"Unexpected error during token verification: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not verify authentication token due to an internal error."
        )

# --- API Endpoints ---
@app.get("/")
async def read_root():
    """A simple root endpoint to check if the server is running."""
    return {"message": "AI Backend is running!"}

@app.post("/chat", response_model=ChatResponse)
async def handle_chat(
    request: ChatRequest,
    user_id: str = Depends(get_current_user_uid),
    chat_service: ChatService = Depends(get_chat_service),
):
    """
    Receives a user's message, generates an AI response, and saves the conversation.
    """
    try:
        await chat_service.generate_and_save_response(
            user_id=user_id,
            user_message=request.user_message,
            client_message_id=request.message_id,
            client_timestamp=request.client_timestamp,
        )
        return ChatResponse()
    except Exception as e:
        logger.error(f"Error in /chat endpoint for user '{user_id}': {e}", exc_info=True)
        # The specific error message will be logged on the server.
        # We return a generic error to the client.
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred while processing your message.",
        )