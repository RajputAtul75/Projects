from rest_framework import serializers


class CopilotRequestSerializer(serializers.Serializer):
    query = serializers.CharField(max_length=500)


class CopilotResponseSerializer(serializers.Serializer):
    structured_query = serializers.DictField()
    products = serializers.ListField(child=serializers.DictField())
    ai_response = serializers.CharField()
    recommendation_type = serializers.CharField()
