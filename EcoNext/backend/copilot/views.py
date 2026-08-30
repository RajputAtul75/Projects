import logging

from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import CopilotRequestSerializer
from .services import run_ecoai_pipeline

logger = logging.getLogger(__name__)


class CopilotAPIView(APIView):
    """EcoAi endpoint — accepts a natural-language shopping query and returns
    product recommendations.

    The pipeline calls the xAI Grok API when XAI_API_KEY is configured and falls
    back to a local rule-based parser and scorer when it isn't, so this endpoint
    works with no external credentials. See copilot/services.py.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = CopilotRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        raw_query = serializer.validated_data["query"].strip()
        if not raw_query:
            return Response(
                {
                    "structured_query": {},
                    "products": [],
                    "ai_response": "Tell me what you're shopping for and I'll find it.",
                    "recommendation_type": "single",
                },
                status=status.HTTP_200_OK,
            )

        try:
            result = run_ecoai_pipeline(raw_query)
        except Exception:
            # Never surface a traceback to the storefront; the copilot is an
            # enhancement, so a failure degrades to a readable message.
            logger.exception("EcoAi pipeline failed for query %r", raw_query)
            return Response(
                {
                    "structured_query": {},
                    "products": [],
                    "ai_response": (
                        "The shopping assistant is temporarily unavailable. "
                        "You can still browse and search the catalogue."
                    ),
                    "recommendation_type": "single",
                },
                status=status.HTTP_200_OK,
            )

        return Response(result, status=status.HTTP_200_OK)
