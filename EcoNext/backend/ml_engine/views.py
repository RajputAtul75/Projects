from rest_framework.decorators import api_view
from rest_framework.response import Response
from .visual_search import VisualSearchEngine

@api_view(['POST'])
def visual_search_view(request):
    if 'image' not in request.FILES:
        return Response({'status': 'error', 'message': 'Image file is required.'}, status=400)

    try:
        image_file = request.FILES['image']
        
        # Instantiate the engine and find similar products
        engine = VisualSearchEngine()
        features = engine.process_image_from_upload(image_file)
        
        if features is None:
            return Response({'status': 'error', 'message': 'Could not process image.'}, status=400)
            
        results = engine.find_similar_products(features)
        
        # Format results for API response
        formatted_results = [
            {
                'product': {
                    'id': p.id,
                    'name': p.name,
                    'description': p.description,
                    'current_price': str(p.current_price),
                    'image_url': p.image_url,
                },
                'similarity_score': score
            } for p, score in results
        ]
        
        return Response({'status': 'success', 'results': formatted_results, 'total_found': len(results)})
    except Exception as e:
        return Response({'status': 'error', 'message': str(e)}, status=500)

