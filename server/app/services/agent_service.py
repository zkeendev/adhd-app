import logging
from functools import lru_cache

from agents import Agent, Runner, TResponseInputItem, set_default_openai_key

from app.config import get_settings

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
"""

class AgentService:
    """
    A service class to encapsulate the AI agent's logic and interaction.
    """
    _agent: Agent

    def __init__(self, api_key: str):
        """
        Initializes the AgentService.

        Args:
            api_key: The OpenAI API key.
        """
        # Configure the Agents SDK with the API key from our settings.
        set_default_openai_key(api_key)
        
        self._agent = Agent(
            name="ADHD_Coach_Agent",
            instructions=_ADHD_COACH_INSTRUCTIONS,
            # We use gpt-4o as it offers a great balance of intelligence and speed.
            # This can be changed later.
            model="gpt-4o",
        )
        logger.info("AI Agent initialized.")

    async def get_response(self, conversation_history: list[TResponseInputItem]) -> str:
        """
        Gets a response from the AI agent based on the conversation history.

        Args:
            conversation_history: A list of previous messages in the conversation.

        Returns:
            The AI's response as a string.
        """
        try:
            logger.info(f"Running agent with {len(conversation_history)} messages in history.")
            # Runner.run executes the agent loop and returns the final result.
            result = await Runner.run(self._agent, conversation_history)
            
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