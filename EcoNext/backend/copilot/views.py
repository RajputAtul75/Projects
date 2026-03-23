from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import CopilotRequestSerializer
from .services import (
    build_pc_bundle,
    extract_structured_query,
    generate_ai_response,
    recommend_products,
    should_return_bundle,
)


class CopilotAPIView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = CopilotRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        raw_query = serializer.validated_data["query"]
        structured_query = extract_structured_query(raw_query)

        if should_return_bundle(structured_query, raw_query):
            recommendation_type = "bundle"
            products = build_pc_bundle(structured_query)
        else:
            recommendation_type = "single"
            products = recommend_products(structured_query, top_n=5)

        ai_response = generate_ai_response(
            raw_query=raw_query,
            sq=structured_query,
            products=products,
            recommendation_type=recommendation_type,
        )

        return Response(
            {
                "structured_query": structured_query.as_dict(),
                "products": products,
                "ai_response": ai_response,
                "recommendation_type": recommendation_type,
            },
            status=status.HTTP_200_OK,
        )
