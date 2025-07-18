import logging
from functools import lru_cache
from firebase_admin import firestore
from agents import Agent, Runner, TResponseInputItem, set_default_openai_key

from app.config import get_settings
from ..tools.reminder_tool import schedule_reminder
from ..models import AgentContext

logger = logging.getLogger(__name__)

# --- Agent Definition ---

# Instructions for the AI agent. This is a crucial part of shaping the AI's personality and function.
# We can refine this over time.
_ADHD_COACH_INSTRUCTIONS = """
You are an expert ADHD coach and a supportive, non-judgmental companion. Your primary goal is to help the user navigate the challenges of ADHD.

Your personality is:
- Empathetic and understanding.
- Patient and encouraging.
- Positive and forward-looking.
- A great listener.

Your core functions are:
- To help users set and break down achievable goals.
- To identify patterns in their behavior and thoughts.
- To provide gentle accountability.
- To offer evidence-based strategies and coping mechanisms for common ADHD challenges like procrastination, time management, and emotional regulation.
- To celebrate small wins and help the user build momentum.

Interaction style:
- Ask open-ended questions to encourage reflection.
- Avoid giving direct advice unless asked. Instead, guide the user to find their own solutions.
- Keep your responses concise and easy to digest. Use formatting like lists or bold text to improve readability.
- Never diagnose or provide medical advice. If the user discusses medical topics, gently redirect them to consult a healthcare professional.

Tool use:
- When a user asks to be reminded of something, invoke the `schedule_reminder` tool.
"""

class AgentService:
    """
    A service class to encapsulate the AI agent's logic and interaction.
    """
    _agent: Agent[AgentContext]

    def __init__(self, api_key: str):
        """
        Initializes the AgentService.

        Args:
            api_key: The OpenAI API key.
        """
        set_default_openai_key(api_key)
        
        self._agent = Agent[AgentContext](
            name="ADHD_Coach_Agent",
            instructions=_ADHD_COACH_INSTRUCTIONS,
            model="gpt-4o",
            tools=[schedule_reminder],
        )
        logger.info("AI Agent initialized.")

    async def get_response(
        self,
        conversation_history: list[TResponseInputItem],
        user_id: str,
        user_timezone: str,
        batch: firestore.WriteBatch
    ) -> str:
        
        try:
            agent_context = AgentContext(
                user_id=user_id,
                user_timezone=user_timezone,
                firestore_batch=batch,
            )

            logger.info(f"Running agent with {len(conversation_history)} messages in history.")
            result = await Runner.run(self._agent, conversation_history, context=agent_context)
            
            final_output = result.final_output
            if isinstance(final_output, str):
                logger.info("Agent returned a string response.")
                return final_output
            else:
                # This case might happen if the agent's output is misconfigured.
                # We'll log it and return a generic response.
                logger.warning(f"Agent returned an unexpected type: {type(final_output)}. Converting to string.")
                return str(final_output)

        except Exception as e:
            logger.error(f"Error running AI agent: {e}", exc_info=True)
            # Provide a fallback response in case of an error.
            return "I'm having a little trouble connecting right now. Please try again in a moment."


# --- Dependency Injection ---

@lru_cache
def get_agent_service() -> AgentService:
    """
    Dependency injector for the AgentService.
    Uses lru_cache to ensure a single instance of the service is created.
    """
    settings = get_settings()
    return AgentService(api_key=settings.openai_api_key)