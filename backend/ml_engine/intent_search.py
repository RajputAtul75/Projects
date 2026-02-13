"""
Intent-Based Search using TF-IDF
Maps user queries to product intents (e.g., "gym" -> shoes, bottle, yoga mat)
"""

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
from products.models import Product
from ml_engine.models import TFIDFIndex
import json

class IntentBasedSearcher:
    def __init__(self):
        self.vectorizer = TfidfVectorizer(
            max_features=1000,
            lowercase=True,
            stop_words='english',
            ngram_range=(1, 2)
        )
    
    def build_intent_catalog(self):
        """Build TF-IDF index for all products"""
        
        # Prepare documents: product name + tags + description
        products = Product.objects.all()
        documents = []
        product_list = []
        
        for product in products:
            # Combine product metadata for intent extraction
            text = f"{product.name} {product.category.name} {' '.join(product.tags)}"
            documents.append(text)
            product_list.append(product)
        
        if not documents:
            return []
        
        # Build TF-IDF matrix
        tfidf_matrix = self.vectorizer.fit_transform(documents)
        
        return product_list, tfidf_matrix, self.vectorizer
    
    def search_by_intent(self, query: str, top_k: int = 5):
        """Search products by intent"""
        
        products, tfidf_matrix, vectorizer = self.build_intent_catalog()
        
        if not products:
            return []
        
        # Transform query
        query_vector = vectorizer.transform([query])
        
        # Calculate similarities
        similarities = cosine_similarity(query_vector, tfidf_matrix)[0]
        
        # Get top-k results
        top_indices = np.argsort(similarities)[-top_k:][::-1]
        
        results = [
            {
                'product': products[idx],
                'similarity_score': float(similarities[idx]),
                'intent_match': self._get_intent_explanation(query, products[idx])
            }
            for idx in top_indices
            if similarities[idx] > 0.1  # Minimum similarity threshold
        ]
        
        return results
    
    def _get_intent_explanation(self, query: str, product: Product) -> str:
        """Explain why product matches the query"""
        query_lower = query.lower()
        
        if query_lower in product.name.lower():
            return f"Direct match in product name"
        elif any(tag.lower() in query_lower for tag in product.tags):
            return f"Matches intent: {query}"
        elif query_lower in product.category.name.lower():
            return f"Found in {product.category.name} category"
        else:
            return f"Related to: {query}"
    
    def extract_intent_tags(self, query: str) -> list:
        """Extract key intent tags from query"""
        
        # Simple keyword extraction
        common_intents = {
            'gym': ['gym shoes', 'water bottle', 'yoga mat', 'dumbbells', 'athlete'],
            'office': ['desk', 'chair', 'stationery', 'monitor', 'laptop'],
            'cooking': ['knife', 'pan', 'spoon', 'cutting board', 'apron'],
            'travel': ['luggage', 'backpack', 'pillow', 'passport holder'],
            'beach': ['swimsuit', 'sunscreen', 'flip flops', 'beach bag', 'sunglasses'],
        }
        
        query_lower = query.lower()
        matched_intents = []
        
        for intent, tags in common_intents.items():
            if intent in query_lower:
                matched_intents.extend(tags)
        
        return matched_intents if matched_intents else [query]
    
    def get_category_recommendations(self, query: str) -> dict:
        """Return category-wise recommendations for a query"""
        
        search_results = self.search_by_intent(query, top_k=20)
        
        categories = {}
        for result in search_results:
            category = result['product'].category.name
            if category not in categories:
                categories[category] = []
            categories[category].append(result)
        
        # Sort by similarity within each category
        for category in categories:
            categories[category].sort(
                key=lambda x: x['similarity_score'],
                reverse=True
            )
        
        return categories
