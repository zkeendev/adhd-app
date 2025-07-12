import os
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict

# Define the root directory of the 'server' application
SERVER_ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

class Settings(BaseSettings):
    """
    Application settings, loaded from environment variables or a .env file.
    """
    # OpenAI API Key
    openai_api_key: str

    # Firebase settings
    firebase_service_account_key_path: str = os.path.join(
        SERVER_ROOT_DIR, 
        'adhd-app-firebase-adminsdk.json'
    )

    # Firestore collection names
    firestore_users_collection: str = "users"
    firestore_conversations_collection: str = "user_conversations"
    firestore_messages_subcollection: str = "messages"

    # pydantic-settings configuration
    model_config = SettingsConfigDict(
        env_file=os.path.join(SERVER_ROOT_DIR, '.env'),
        env_file_encoding='utf-8',
        extra='ignore' # Ignore extra fields from the env file
    )

@lru_cache
def get_settings() -> Settings:
    """
    Returns a cached instance of the Settings.
    Using lru_cache ensures the .env file is read only once.
    """
    return Settings()