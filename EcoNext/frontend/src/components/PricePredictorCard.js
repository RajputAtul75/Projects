import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { TrendingDown, TrendingUp, AlertCircle } from 'lucide-react';
import '../styles/price-predictor.css';

export const PricePredictorCard = ({ prediction, currentPrice }) => {
  const [displayData, setDisplayData] = useState(null);

  useEffect(() => {
    if (prediction) {
      setDisplayData(prediction);
    }
  }, [prediction]);

  if (!displayData) {
    return (
      <motion.div 
        className="price-predictor-placeholder"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
      >
        <p>No price prediction available yet</p>
      </motion.div>
    );
  }

  const getRecommendationIcon = () => {
    if (displayData.recommendation === 'best_price') {
      return <TrendingUp className="icon-up" size={28} />;
    } else if (displayData.recommendation === 'wait') {
      return <TrendingDown className="icon-down" size={28} />;
    } else {
      return <AlertCircle className="icon-neutral" size={28} />;
    }
  };

  const getRecommendationBg = () => {
    switch (displayData.recommendation) {
      case 'best_price':
        return 'bg-success';
      case 'wait':
        return 'bg-warning';
      default:
        return 'bg-neutral';
    }
  };

  const getRecommendationText = () => {
    switch (displayData.recommendation) {
      case 'best_price':
        return 'Best Price Now! 🟢';
      case 'wait':
        return 'Wait for Better Offer 🟡';
      default:
        return 'Neutral Price 🔵';
    }
  };

  const getPriceChange = () => {
    if (!displayData.price_change) return 0;
    return parseFloat(displayData.price_change).toFixed(1);
  };

  const getConfidence = () => {
    if (!displayData.confidence_score) return 0;
    return Math.round(displayData.confidence_score * 100);
  };

  const get7DayPrices = () => {
    const prices = [];
    for (let i = 1; i <= 7; i++) {
      prices.push(displayData[`day${i}_price`] || currentPrice);
    }
    return prices;
  };

  const prices = get7DayPrices();
  const minPrice = Math.min(...prices);
  const maxPrice = Math.max(...prices);
  const priceRange = maxPrice - minPrice;

  return (
    <motion.div
      className={`price-predictor-card ${getRecommendationBg()}`}
      initial={{ opacity: 0, scale: 0.95, y: 20 }}
      animate={{ opacity: 1, scale: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      whileHover={{ y: -5 }}
    >
      {/* Header */}
      <div className="predictor-header">
        <div className="header-content">
          <span className="predictor-title">📊 7-Day Price Prediction</span>
          <motion.div
            className="recommendation-badge"
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: 'spring', stiffness: 200, damping: 10 }}
          >
            {getRecommendationIcon()}
            <span className="recommendation-text">{getRecommendationText()}</span>
          </motion.div>
        </div>
      </div>

      {/* Price Analysis */}
      <div className="price-analysis">
        <div className="analysis-item">
          <span className="label">Current Price</span>
          <div className="value">${parseFloat(currentPrice).toFixed(2)}</div>
        </div>

        <div className="analysis-item">
          <span className="label">7-Day Avg</span>
          <div className="value">
            ${(prices.reduce((a, b) => a + b, 0) / 7).toFixed(2)}
          </div>
        </div>

        <div className="analysis-item">
          <span className="label">Expected Change</span>
          <div className={`value ${getPriceChange() < 0 ? 'negative' : 'positive'}`}>
            {getPriceChange() > 0 ? '+' : ''}{getPriceChange()}%
          </div>
        </div>

        <div className="analysis-item">
          <span className="label">Confidence</span>
          <div className="confidence-bar">
            <div className="confidence-fill" style={{ width: `${getConfidence()}%` }}>
              {getConfidence()}%
            </div>
          </div>
        </div>
      </div>

      {/* 7-Day Forecast Chart */}
      <div className="forecast-chart">
        <div className="chart-title">7-Day Price Forecast</div>
        <div className="chart-container">
          <div className="chart-bars">
            {prices.map((price, index) => {
              const normalizedHeight = priceRange > 0 
                ? ((price - minPrice) / priceRange) * 100 + 20
                : 50;
              
              return (
                <motion.div
                  key={index}
                  className="chart-bar-wrapper"
                  initial={{ height: 0 }}
                  animate={{ height: '100%' }}
                  transition={{ delay: index * 0.05, duration: 0.5 }}
                >
                  <motion.div
                    className="chart-bar"
                    style={{ height: `${normalizedHeight}%` }}
                    initial={{ scaleY: 0 }}
                    animate={{ scaleY: 1 }}
                    transition={{ delay: index * 0.05 + 0.2, duration: 0.5 }}
                    whileHover={{ scaleY: 1.1 }}
                  >
                    <span className="price-tooltip">
                      ${parseFloat(price).toFixed(2)}
                    </span>
                  </motion.div>
                  <span className="day-label">Day {index + 1}</span>
                </motion.div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Recommendation Message */}
      <motion.div
        className={`recommendation-message ${displayData.recommendation}`}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
      >
        {displayData.recommendation === 'best_price' && (
          <>
            <h4>🎯 Great Deal!</h4>
            <p>This is currently the best price. Historical data suggests the price will increase or stay stable in the next 7 days. Consider buying now!</p>
          </>
        )}
        {displayData.recommendation === 'wait' && (
          <>
            <h4>💰 Hold On!</h4>
            <p>Our model predicts a price drop in the coming days. You might get a better deal if you wait. Average predicted price drop: {Math.abs(getPriceChange()).toFixed(1)}%</p>
          </>
        )}
        {displayData.recommendation === 'neutral' && (
          <>
            <h4>⏸️ Stable Price</h4>
            <p>The price is expected to remain stable over the next 7 days. Feel free to buy whenever it's convenient for you.</p>
          </>
        )}
      </motion.div>

      {/* Disclaimer */}
      <p className="disclaimer">
        💡 Predictions are based on historical pricing data using Linear Regression ML model. Actual prices may vary.
      </p>
    </motion.div>
  );
};

export default PricePredictorCard;
