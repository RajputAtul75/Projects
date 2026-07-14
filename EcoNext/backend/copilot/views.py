from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import CopilotRequestSerializer
from .services import run_ecoai_pipeline


class CopilotAPIView(APIView):
    """EcoAi endpoint — accepts a natural-language shopping query and returns
    AI-powered product recommendations via the Grok two-pass pipeline."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = CopilotRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        raw_query = serializer.validated_data["query"]
        result = run_ecoai_pipeline(raw_query)

        return Response(result, status=status.HTTP_200_OK)
