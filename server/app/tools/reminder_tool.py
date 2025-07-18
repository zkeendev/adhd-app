import logging
import dateparser
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
from agents import RunContextWrapper, function_tool
from firebase_admin import firestore
from ..models import AgentContext, ScheduledNotification


logger = logging.getLogger(__name__)

# --- Custom exceptions ---

class DateParsingError(ValueError):
    """Custom exception for date parsing and validation errors."""
    pass

# --- Function tool definition ---

@function_tool
def schedule_reminder(context: RunContextWrapper[AgentContext], datetime_phrase: str, reminder_content: str) -> str:
    try:
        # Extract dependencies from context
        agent_context: AgentContext = context.context
        user_id = agent_context.user_id
        user_timezone = agent_context.user_timezone
        batch = agent_context.firestore_batch

        # Parse and validate the date string
        parsed_utc = _parse_and_validate(datetime_phrase, user_timezone)

        # Add the reminder document to the Firestore batch
        _add_reminder_to_batch(
            batch=batch,
            user_id=user_id,
            reminder_content=reminder_content,
            parsed_utc=parsed_utc,
            user_timezone=user_timezone
        )
        logger.info(f"Reminder for user {user_id} successfully added to Firestore batch.")

        parsed_local = parsed_utc.astimezone(ZoneInfo(user_timezone))
        pretty_local = _format_pretty(parsed_local)
        return f"SUCCESS. Reminder was scheduled for {pretty_local} ({user_timezone}). Confirm the details with the user."
    
    except DateParsingError as e:
        return str(e)
    
    except Exception as e:
        logger.error(f"Failed to schedule reminder for user {user_id}: {e}", exc_info=True)
        return "Something went wrong while setting the reminder."
    
# --- Private helper functions ----
    
def _format_pretty(dt: datetime) -> str:
    """
    Formats a datetime object into a human-friendly string.

    Example:
        "Tuesday, July 16 at 3:45pm PDT"

    Args:
        dt (datetime): A timezone-aware datetime object.

    Returns:
        str: A formatted date string with weekday, month, time, and timezone abbreviation.
    """
    weekday = dt.strftime("%A")
    month = dt.strftime("%B")
    day = dt.day
    hour = dt.hour % 12 or 12
    minute = dt.minute
    ampm = dt.strftime("%p").lower()
    tz_abbrev = dt.tzname() or ""

    return f"{weekday}, {month} {day} at {hour}:{minute:02d}{ampm} {tz_abbrev}".strip()

def _parse_and_validate(datetime_phrase: str, user_timezone: str) -> datetime:
    """
    Parses a natural language datetime phrase and validates that it's in the future.

    Args:
        datetime_phrase (str): A natural language expression like "tomorrow at 3pm".
        user_timezone (str): The user's local timezone (e.g., "America/Los_Angeles").

    Returns:
        datetime: A timezone-aware UTC datetime object representing the parsed time.

    Raises:
        DateParsingError: If the phrase cannot be parsed or refers to a past time.
    """
    parsed_utc = dateparser.parse(
        datetime_phrase,
        settings={
            'TIMEZONE': user_timezone,
            'TO_TIMEZONE': 'UTC',
            'RETURN_AS_TIMEZONE_AWARE': True,
            'PREFER_DATES_FROM': 'future',
        },
    )

    if not parsed_utc:
        raise DateParsingError(f"Could not parse '{datetime_phrase}'. Try being more specific.")

    if parsed_utc <= datetime.now(timezone.utc):
        raise DateParsingError("Date must be in the future.")

    return parsed_utc

def _add_reminder_to_batch(
    batch: firestore.WriteBatch,
    user_id: str,
    reminder_content: str,
    parsed_utc: datetime,
    user_timezone: str
) -> None:
    db = batch._client
    doc_ref = db.collection("scheduled_notifications").document()
    
    reminder = ScheduledNotification(
        user_id=user_id,
        title="Your Reminder",
        body=reminder_content,
        scheduled_at=parsed_utc,
        status="pending",
        created_at=firestore.SERVER_TIMESTAMP,
        user_timezone=user_timezone,
    )
    
    batch.set(doc_ref, reminder.model_dump(by_alias=True))