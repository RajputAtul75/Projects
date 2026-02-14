"""
Visual Search using Image Histograms (OpenCV-based)
Extract features from images and find similar products
"""

import cv2
import numpy as np
import io
from typing import List, Tuple
import json
from products.models import Product
from ml_engine.models import ImageFeatures
from sklearn.metrics.pairwise import cosine_similarity
import requests
from PIL import Image

class VisualSearchEngine:
    def __init__(self):
        """Initialize Visual Search Engine using histogram-based features"""
        self.feature_dim = 256  # Histogram bins
    
    def extract_features(self, image_bytes):
        """Extract histogram features from image"""
        try:
            # Convert bytes to numpy array
            if isinstance(image_bytes, bytes):
                nparr = np.frombuffer(image_bytes, np.uint8)
                img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            else:
                # If PIL Image
                img = cv2.cvtColor(np.array(image_bytes), cv2.COLOR_RGB2BGR)
            
            if img is None:
                return None
            
            # Resize for consistent feature extraction
            img = cv2.resize(img, (224, 224))
            
            # Convert to HSV for better color representation
            hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
            
            # Extract histogram features from each channel
            hist_h = cv2.calcHist([hsv], [0], None, [64], [0, 256])
            hist_s = cv2.calcHist([hsv], [1], None, [64], [0, 256])
            hist_v = cv2.calcHist([hsv], [2], None, [64], [0, 256])
            
            # Normalize histograms
            hist_h = cv2.normalize(hist_h, hist_h).flatten()
            hist_s = cv2.normalize(hist_s, hist_s).flatten()
            hist_v = cv2.normalize(hist_v, hist_v).flatten()
            
            # Combine all features
            features = np.concatenate([hist_h, hist_s, hist_v])
            
            return features.astype(np.float32)
            
        except Exception as e:
            print(f"Error extracting features: {e}")
            return None
    
    def process_image_from_url(self, image_url: str):
        """Download and process image from URL"""
        try:
            response = requests.get(image_url, timeout=10)
            image = Image.open(io.BytesIO(response.content)).convert('RGB')
            return self.extract_features(image)
        except Exception as e:
            print(f"Error processing image: {e}")
            return None
    
    def process_image_from_upload(self, image_file):
        """Process uploaded image file"""
        try:
            image = Image.open(image_file).convert('RGB')
            return self.extract_features(image)
        except Exception as e:
            print(f"Error processing image: {e}")
            return None
    
    def find_similar_products(self, features: np.ndarray, top_k: int = 5) -> List[Tuple[Product, float]]:
        """Find similar products based on image features"""
        
        # Get all product features from database
        all_features = ImageFeatures.objects.all()
        
        if not all_features.exists():
            return []
        
        # Stack all features
        catalog_features = []
        products = []
        
        for img_feat in all_features:
            try:
                feat_vector = np.array(json.loads(img_feat.features_vector))
                catalog_features.append(feat_vector)
                products.append(img_feat.product)
            except:
                continue
        
        if not catalog_features:
            return []
        
        catalog_features = np.array(catalog_features)
        
        # Calculate cosine similarity
        query_features = features.reshape(1, -1)
        similarities = cosine_similarity(query_features, catalog_features)[0]
        
        # Get top-k most similar
        top_indices = np.argsort(similarities)[-top_k:][::-1]
        
        results = [
            (products[idx], float(similarities[idx]))
            for idx in top_indices
        ]
        
        return results
    
    def index_product_image(self, product: Product):
        """Extract and save features for a product image"""
        if not product.image_url:
            return None
        
        features = self.process_image_from_url(product.image_url)
        
        if features is None:
            return None
        
        # Save features to database
        import hashlib
        image_hash = hashlib.sha256(
            json.dumps(features.tolist()).encode()
        ).hexdigest()
        
        img_feat_obj, created = ImageFeatures.objects.get_or_create(
            product=product,
            defaults={
                'features_vector': json.dumps(features.tolist()),
                'image_hash': image_hash
            }
        )
        
        return img_feat_obj
