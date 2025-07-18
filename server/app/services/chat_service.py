from datetime import datetime
import logging
from functools import lru_cache
from typing import Any, Dict, List

from firebase_admin import firestore
from agents import TResponseInputItem

from ..config import get_settings
from ..repositories import ChatRepository
from ..services.agent_service import AgentService, get_agent_service
from ..services.notification_service import NotificationService, get_notification_service


logger = logging.getLogger(__name__)

class ChatService:
    """
    Service to orchestrate chat interactions, including fetching history,
    generating AI responses, and persisting conversation turns.
    """
    _chat_repo: ChatRepository
    _agent_service: AgentService
    _notification_service: NotificationService

    def __init__(self, chat_repo: ChatRepository, agent_service: AgentService,notification_service: NotificationService):
        self._chat_repo = chat_repo
        self._agent_service = agent_service
        self._notification_service = notification_service

    def _format_history_for_agent(self, history: List[Dict[str, Any]]) -> List[TResponseInputItem]:
        """
        Converts Firestore message history into the format expected by the OpenAI Agents SDK.
        """
        formatted_history: List[TResponseInputItem] = []
        for message in history:
            role = "assistant" if message.get("senderId") == "AI_ASSISTANT" else "user"
            content = message.get("text", "")
            if content:
                formatted_history.append({"role": role, "content": content})
        return formatted_history

    async def generate_and_save_response(
        self,
        user_id: str,
        user_message: str,
        client_message_id: str,
        client_timestamp: datetime,
    ):
        db = firestore.client()
        batch = db.batch()

        try:
            user_profile = self._chat_repo.get_user_profile(user_id)
            user_timezone = user_profile.get("timezone", "UTC") if user_profile else "UTC"
            
            history_docs = self._chat_repo.get_message_history(user_id)
            conversation_history = self._format_history_for_agent(history_docs)
            conversation_history.append({"role": "user", "content": user_message})

            logger.info(f"Generating AI response for user '{user_id}'.")
            ai_response_text = await self._agent_service.get_response(
                conversation_history=conversation_history,
                user_id=user_id,
                user_timezone=user_timezone,
                batch=batch,
            )

            user_message_payload = {
                "text": user_message,
                "senderId": user_id,
                "timestamp": client_timestamp,
            }

            ai_message_payload = {
                "text": ai_response_text,
                "senderId": "AI_ASSISTANT",
                "timestamp": firestore.SERVER_TIMESTAMP,
            }

            messages_collection_ref = db.collection(self._chat_repo._conversations_collection).document(user_id).collection(self._chat_repo._messages_subcollection)
            user_msg_ref = messages_collection_ref.document(client_message_id)
            ai_msg_ref = messages_collection_ref.document()

            batch.set(user_msg_ref, user_message_payload)
            batch.set(ai_msg_ref, ai_message_payload)

            batch.commit()
            logger.info(f"Successfully committed chat batch to Firestore.")

            logger.info(f"Attempting to send notification to user '{user_id}'.")
            fcm_tokens = self._chat_repo.get_user_fcm_tokens(user_id)
            if fcm_tokens:
                self._notification_service.send_notification_to_devices(
                    tokens=fcm_tokens,
                    title="You have a new message!",
                    body=ai_response_text[:100] + ('...' if len(ai_response_text) > 100 else '')
                )
            else:
                logger.info(f"User '{user_id}' has no FCM notkens. Skipping notification.")


        except Exception as e:
            logger.error(
                f"An error occurred in ChatService for user '{user_id}': {e}",
                exc_info=True,
            )
            # In a real-world scenario, you might want to save an error message
            # to Firestore or notify the user in some way. For now, we just log it.
            raise # Re-raise the exception to be handled by the API endpoint


# --- Dependency Injection ---

@lru_cache
def get_chat_service() -> ChatService:
    """
    Dependency injector for the ChatService.
    """
    settings = get_settings()
    # Note: firestore.client() is initialized in main.py
    db_client = firestore.client()
    
    chat_repo = ChatRepository(db_client=db_client, settings=settings)
    agent_service = get_agent_service()
    notification_service = get_notification_service()
    
    return ChatService(chat_repo=chat_repo, agent_service=agent_service, notification_service=notification_service)