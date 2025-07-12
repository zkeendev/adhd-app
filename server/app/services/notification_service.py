import logging
from typing import List
from firebase_admin import messaging

logger = logging.getLogger(__name__)

class NotificationService:
    """
    A service to handle sending Firebase Cloud Messaging notifications.
    """
    def send_notification_to_devices(self, tokens: List[str], title: str, body: str):
        """
        Sends a notification to a list of device tokens.

        Args:
            tokens: A list of FCM registration tokens.
            title: The title of the notification.
            body: The body text of the notification.
        """
        if not tokens:
            logger.info("No FCM tokens provided, skipping notification.")
            return

        notification_payload = messaging.Notification(title=title, body=body)
        
        message = messaging.MulticastMessage(
            tokens=tokens,
            notification=notification_payload,
            data={
                'title': title,
                'body': body,
            }
        )

        try:
            # Send the message
            response: messaging.BatchResponse = messaging.send_each_for_multicast(message)
            
            # Log the results
            logger.info(f"{response.success_count} messages were sent successfully.")
            if response.failure_count > 0:
                self._log_failed_sends(response, tokens)

        except Exception as e:
            logger.error(f"An unexpected error occurred while sending FCM message: {e}", exc_info=True)

    def _log_failed_sends(self, response: messaging.BatchResponse, tokens: List[str]):
        """
        Logs details about messages that failed to send.
        """
        failed_responses = response.responses
        failed_tokens = []
        
        for idx, resp in enumerate(failed_responses):
            if not resp.success:
                # The order of responses corresponds to the order of the registration tokens.
                failed_tokens.append(tokens[idx])
                # Log the specific error for each failed token
                error_code = resp.exception.code if resp.exception else 'UNKNOWN_ERROR'
                logger.warning(
                    f"Message sent to token '{tokens[idx]}' failed with error code: {error_code}"
                )
        
        # You could also implement logic here to remove these failed_tokens from your database.
        # For now, we are just logging them.
        logger.warning(f"List of tokens that caused failures: {failed_tokens}")


# --- Dependency Injection ---
# We can use lru_cache for a simple singleton pattern
from functools import lru_cache

@lru_cache
def get_notification_service() -> NotificationService:
    return NotificationService()