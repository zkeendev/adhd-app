import logging
from typing import List, Dict, Any, Iterable

from google.cloud.firestore_v1.client import Client as FirestoreClient
from google.cloud.firestore_v1.collection import CollectionReference
from google.cloud.firestore_v1.query import Query
from google.cloud.firestore_v1.document import DocumentSnapshot

from .config import Settings

logger = logging.getLogger(__name__)

class ChatRepository:
    """
    Handles all database operations related to chat messages in Firestore.
    """
    _db: FirestoreClient
    _users_collection: str
    _conversations_collection: str
    _messages_subcollection: str

    def __init__(self, db_client: FirestoreClient, settings: Settings):
        """
        Initializes the repository with a Firestore client and settings.
        """
        self._db = db_client
        self._users_collection = settings.firestore_users_collection
        self._conversations_collection = settings.firestore_conversations_collection
        self._messages_subcollection = settings.firestore_messages_subcollection

    def get_message_history(self, user_id: str) -> List[Dict[str, Any]]:
        """
        Retrieves the message history for a given user, ordered by timestamp.
        """
        try:
            messages_ref: CollectionReference = self._db.collection(self._conversations_collection) \
                .document(user_id) \
                .collection(self._messages_subcollection)
            
            query: Query = messages_ref.order_by('timestamp', direction=Query.ASCENDING)
            
            docs: Iterable[DocumentSnapshot] = query.stream()
            
            history: List[Dict[str, Any]] = [doc.to_dict() for doc in docs]
            
            logger.info(f"Fetched {len(history)} messages for user '{user_id}'.")
            return history
        except Exception as e:
            logger.error(f"Could not fetch message history for user '{user_id}': {e}", exc_info=True)
            raise

    def add_messages(self, user_id: str, messages: List[Dict[str, Any]]):
        """
        Adds a batch of new messages to a user's conversation history.
        Each message in the list can optionally specify an 'id'.
        """
        try:
            batch = self._db.batch()
            user_messages_ref: CollectionReference = self._db.collection(self._conversations_collection) \
                .document(user_id) \
                .collection(self._messages_subcollection)

            for message in messages:
                message_id = message.get("id")
                message_data = message.get("data", {})

                if message_id:
                    # Use the provided ID for the document reference
                    doc_ref = user_messages_ref.document(message_id)
                else:
                    # Let Firestore auto-generate the ID
                    doc_ref = user_messages_ref.document()
                
                batch.set(doc_ref, message_data)
            
            batch.commit()
            logger.info(f"Successfully added {len(messages)} new messages for user '{user_id}'.")
        except Exception as e:
            logger.error(f"Could not add messages for user '{user_id}': {e}", exc_info=True)
            raise

    def get_user_fcm_tokens(self, user_id: str) -> list[str]:
        try:
            user_doc_ref = self._db.collection(self._users_collection).document(user_id)
            user_doc = user_doc_ref.get()
            if not user_doc.exists:
                logger.warning(f"User document not found for user_id: {user_id}")
                return []
            
            user_data = user_doc.to_dict()
            tokens = user_data.get("fcmTokens", [])
            if not isinstance(tokens, list):
                logger.warning(f"fcmTokens field is not a list for user_id: {user_id}")
                return []
            return tokens
        except Exception as e:
            logger.error(f"Error fetching FCM tokens for user_id: '{user_id}")
            return []