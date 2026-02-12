import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { ChevronLeft, ShoppingCart, AlertCircle } from 'lucide-react';
import { apiService } from './api';
import { AnimatedButton, Skeleton } from './components';

export const ProductDetailView = ({ productId, onAddToCart, onBack }) => {
  const [product, setProduct] = useState(null);
  const [prediction, setPrediction] = useState(null);
  const [loading, setLoading] = useState(true);
  const [imageLoaded, setImageLoaded] = useState(false);

  useEffect(() => {
    const loadProduct = async () => {
      try {
        const data = await apiService.getProductDetail(productId);
        if (data.status === 'success') {
          setProduct(data.product);
          setPrediction(data.price_prediction);
        }
      } catch (error) {
        console.error('Error loading product:', error);
      }
      setLoading(false);
    };
    loadProduct();
  }, [productId]);

  const containerVariants = {
    initial: { opacity: 0 },
    animate: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.2,
      },
    },
  };

  const itemVariants = {
    initial: { opacity: 0, y: 20 },
    animate: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.4 },
    },
  };

  if (loading) {
    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
      >
        <Skeleton count={1} variant="card" />
      </motion.div>
    );
  }

  if (!product) {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        className="empty-state"
      >
        <AlertCircle size={64} style={{ marginBottom: '1rem', opacity: 0.5 }} />
        <h2>Product not found</h2>
        <p>The product you're looking for doesn't exist or has been removed.</p>
        <AnimatedButton onClick={onBack} variant="primary">
          <ChevronLeft size={20} />
          Go Back
        </AnimatedButton>
      </motion.div>
    );
  }

  const getPredictionColor = () => {
    if (!prediction) return '#999';
    return prediction.recommendation === 'best_price' ? '#4CAF50' : '#FF9800';
  };

  const getPredictionBg = () => {
    if (!prediction) return '#f5f5f5';
    return prediction.recommendation === 'best_price' ? '#e8f5e9' : '#fff3e0';
  };

  return (
    <motion.div
      className="product-detail"
      variants={containerVariants}
      initial="initial"
      animate="animate"
    >
      {/* Back Button */}
      <motion.div variants={itemVariants}>
        <AnimatedButton 
          onClick={onBack} 
          variant="outline"
          size="sm"
        >
          <ChevronLeft size={18} />
          Back
        </AnimatedButton>
      </motion.div>

      {/* Main Content */}
      <motion.div 
        className="product-detail-grid"
        variants={itemVariants}
      >
        {/* Image */}
        <motion.div 
          className="product-detail-image"
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.4 }}
        >
          {product.image_url ? (
            <>
              <motion.img
                src={product.image_url}
                alt={product.name}
                onLoad={() => setImageLoaded(true)}
                initial={{ opacity: 0 }}
                animate={{ opacity: imageLoaded ? 1 : 0 }}
              />
              {!imageLoaded && <Skeleton width="100%" height="400px" />}
            </>
          ) : (
            <div className="no-image">No Image Available</div>
          )}
        </motion.div>

        {/* Details */}
        <motion.div className="product-detail-content">
          {/* Title */}
          <motion.h1 variants={itemVariants}>
            {product.name}
          </motion.h1>

          {/* Category */}
          <motion.p 
            className="product-category-text"
            variants={itemVariants}
          >
            {product.category?.name || 'Uncategorized'}
          </motion.p>

          {/* Price */}
          <motion.div 
            className="price-section"
            variants={itemVariants}
          >
            <motion.div 
              className="current-price"
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.3 }}
            >
              ${product.current_price?.toFixed(2) || '0.00'}
            </motion.div>
            {product.original_price && product.original_price > product.current_price && (
              <motion.span 
                className="original-price"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.4 }}
              >
                ${product.original_price.toFixed(2)}
              </motion.span>
            )}
          </motion.div>

          {/* Prediction */}
          {prediction && (
            <motion.div 
              className="prediction-box"
              style={{ backgroundColor: getPredictionBg(), borderLeftColor: getPredictionColor() }}
              variants={itemVariants}
              whileHover={{ scale: 1.02 }}
            >
              <div className="prediction-header">
                <span className="prediction-icon">📊</span>
                <strong>7-Day Price Prediction</strong>
              </div>
              {prediction.recommendation === 'best_price' && (
                <p>🟢 <strong>Best Price!</strong> This is a great price to buy. Price is likely to increase.</p>
              )}
              {prediction.recommendation === 'wait' && (
                <p>🟡 <strong>Wait</strong> - Price may drop further. Consider waiting a few days.</p>
              )}
              {prediction.recommendation === 'neutral' && (
                <p>⚪ <strong>Neutral</strong> - Price is expected to remain stable.</p>
              )}
              <p className="confidence">
                Confidence: {Math.round((prediction.confidence_score || 0) * 100)}%
              </p>
            </motion.div>
          )}

          {/* Description */}
          {product.description && (
            <motion.div 
              className="description-section"
              variants={itemVariants}
            >
              <h3>Description</h3>
              <p>{product.description}</p>
            </motion.div>
          )}

          {/* Stock Status */}
          {product.stock_quantity !== undefined && (
            <motion.div 
              className="stock-section"
              variants={itemVariants}
            >
              <span className={`stock-badge ${product.stock_quantity > 0 ? 'in-stock' : 'out-of-stock'}`}>
                {product.stock_quantity > 0 ? `✓ In Stock (${product.stock_quantity})` : 'Out of Stock'}
              </span>
            </motion.div>
          )}

          {/* Actions */}
          <motion.div 
            className="action-buttons"
            variants={itemVariants}
          >
            <AnimatedButton 
              onClick={() => onAddToCart(product)}
              variant="primary"
              size="lg"
            >
              <ShoppingCart size={20} />
              Add to Cart
            </AnimatedButton>
            <AnimatedButton 
              onClick={onBack}
              variant="outline"
              size="lg"
            >
              Continue Shopping
            </AnimatedButton>
          </motion.div>
        </motion.div>
      </motion.div>
    </motion.div>
  );
};

export default ProductDetailView;
