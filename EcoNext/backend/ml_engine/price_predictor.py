"""
Price Predictor using Linear Regression
Predicts next 7 days price trend based on historical data
"""

import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler
from products.models import Product, PriceHistory
from django.utils import timezone
from datetime import timedelta, datetime
from ml_engine.models import PricePrediction

class PricePredictor:
    def __init__(self, days_history=60):
        self.days_history = days_history
        self.model = LinearRegression()
        self.scaler = StandardScaler()
    
    def get_historical_prices(self, product):
        """Get price history for the product"""
        cutoff_date = timezone.now().date() - timedelta(days=self.days_history)
        history = PriceHistory.objects.filter(
            product=product,
            date__gte=cutoff_date
        ).order_by('date')
        
        prices = [float(h.price) for h in history]
        dates = [h.date for h in history]
        
        return prices, dates
    
    def prepare_features(self, prices):
        """Convert prices to features for ML"""
        if len(prices) < 5:
            return None, None
        
        X = np.arange(len(prices)).reshape(-1, 1)
        y = np.array(prices)
        
        X_scaled = self.scaler.fit_transform(X)
        return X_scaled, y
    
    def train_and_predict(self, product):
        """Train model and predict next 7 days"""
        prices, dates = self.get_historical_prices(product)
        
        if len(prices) < 5:
            return None
        
        X, y = self.prepare_features(prices)
        if X is None:
            return None
        
        self.model.fit(X, y)
        
        # Predict next 7 days
        current_price = float(product.current_price)
        future_X = np.arange(len(prices), len(prices) + 7).reshape(-1, 1)
        future_X_scaled = self.scaler.transform(future_X)
        
        predictions = self.model.predict(future_X_scaled)
        
        # Determine recommendation
        average_future_price = np.mean(predictions)
        price_change_percent = ((average_future_price - current_price) / current_price) * 100
        
        if price_change_percent < -5:
            recommendation = 'wait'
        elif price_change_percent > 5:
            recommendation = 'best_price'
        else:
            recommendation = 'neutral'
        
        # Calculate confidence (R² score)
        confidence = self.model.score(X, y)
        
        return {
            'predictions': predictions,
            'recommendation': recommendation,
            'confidence': max(0, confidence),
            'price_change': price_change_percent
        }
    
    def save_predictions(self, product):
        """Save predictions to database"""
        result = self.train_and_predict(product)
        
        if result is None:
            return None
        
        predictions = result['predictions']
        
        prediction_obj = PricePrediction.objects.create(
            product=product,
            day1_price=predictions[0],
            day2_price=predictions[1],
            day3_price=predictions[2],
            day4_price=predictions[3],
            day5_price=predictions[4],
            day6_price=predictions[5],
            day7_price=predictions[6],
            price_change=result['price_change'],
            recommendation=result['recommendation'],
            confidence_score=result['confidence']
        )
        
        return prediction_obj
