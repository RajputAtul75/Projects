from django.http import JsonResponse

def test(request):
    return JsonResponse({"message": "EcoNext API working!"})
