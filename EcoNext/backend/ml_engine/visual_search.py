"""
Visual Search using Image Histograms (OpenCV-based)
Extract features from images and find similar products
"""

import cv2
import numpy as np
from PIL import Image
from products.models import Product
import os
from django.conf import settings

class VisualSearchEngine:
    def __init__(self):
        self.feature_vectors = self._load_or_create_feature_vectors()

    def _extract_features(self, image_path_or_stream):
        """Extracts a feature vector (color histogram) from an image."""
        try:
            if isinstance(image_path_or_stream, str):
                image = Image.open(image_path_or_stream).convert('RGB')
            else:
                # Assuming it's an in-memory file stream
                image = Image.open(image_path_or_stream).convert('RGB')
            
            image = image.resize((128, 128))
            cv_image = np.array(image)
            hist = cv2.calcHist([cv_image], [0, 1, 2], None, [8, 8, 8], [0, 256, 0, 256, 0, 256])
            cv2.normalize(hist, hist)
            return hist.flatten()
        except Exception as e:
            print(f"Error extracting features: {e}")
            return None

    def _load_or_create_feature_vectors(self):
        """Loads or generates feature vectors for all products."""
        vectors_path = os.path.join(settings.BASE_DIR, 'ml_engine', 'feature_vectors.npy')
        if os.path.exists(vectors_path):
            try:
                return np.load(vectors_path, allow_pickle=True).item()
            except Exception:
                pass # If file is corrupted, regenerate

        print("Generating feature vectors for all products...")
        feature_vectors = {}
        # In a real app with media files, you would iterate through products
        # and their images here. For now, we create an empty placeholder.
        
        np.save(vectors_path, feature_vectors)
        print("Feature vectors file created (currently empty).")
        return feature_vectors

    def search(self, query_image_stream, top_k=10):
        """Finds the most similar products to the query image."""
        query_features = self._extract_features(query_image_stream)
        if query_features is None or not hasattr(self, 'feature_vectors'):
            return []

        results = []
        for product_id, feature_vector in self.feature_vectors.items():
            distance = cv2.compareHist(query_features, feature_vector, cv2.HISTCMP_CHISQR)
            results.append((product_id, distance))
        
        if not results:
            return []

        results.sort(key=lambda x: x[1])

        similar_products = []
        for product_id, distance in results[:top_k]:
            try:
                product = Product.objects.get(id=product_id)
                # Convert distance to a similarity score (0-1), higher is better
                similarity = max(0, 1 - (distance / 100)) 
                similar_products.append({
                    'product': product,
                    'similarity_score': similarity
                })
            except Product.DoesNotExist:
                continue
        
        return similar_products

# Instantiate the engine for use in views
visual_search_engine = VisualSearchEngine()
