import React, { useState, useEffect } from 'react';
import './modern-styles.css';
import './App.css';
import './auth-styles.css';
import { apiService } from './api';
import LoginPage from './LoginPage';
import SignupPage from './SignupPage';
import ProductDetailView from './ProductDetailView';
import CheckoutPage from './CheckoutPage';
import ProfilePage from './ProfilePage';
import { 
  AnimatedButton, 
  ProductCard, 
  HeroSection, 
  Modal, 
  Skeleton 
} from './components';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight, Leaf } from 'lucide-react';

function App() {
  const [currentPage, setCurrentPage] = useState('home');
  const [products, setProducts] = useState([]);
  const [searchResults, setSearchResults] = useState(null);
  const [cart, setCart] = useState([]);
  const [trendingProducts, setTrendingProducts] = useState([]);
  const [featuredProducts, setFeaturedProducts] = useState([]);
  const [carouselIndex, setCarouselIndex] = useState(0);
  const [loading, setLoading] = useState(false);
  const [alert, setAlert] = useState(null);
  const [user, setUser] = useState(null);
  const [authToken, setAuthToken] = useState(localStorage.getItem('authToken'));

  // Load user on mount
  useEffect(() => {
    loadProducts();
    loadTrendingProducts();
    checkUserSession();
  }, []);

  // Auto-rotate carousel every 5 seconds
  useEffect(() => {
    if (featuredProducts.length > 0) {
      const timer = setInterval(() => {
        setCarouselIndex((prev) => (prev + 1) % featuredProducts.length);
      }, 5000);
      return () => clearInterval(timer);
    }
  }, [featuredProducts]);

  const checkUserSession = () => {
    const token = localStorage.getItem('authToken');
    const savedUser = localStorage.getItem('user');
    if (token && savedUser) {
      setUser(JSON.parse(savedUser));
      setAuthToken(token);
    }
  };

  const handleLoginSuccess = (response) => {
    setUser(response.user);
    setAuthToken(response.tokens.access);
    setCurrentPage('home');
    showAlert('Welcome! You are now logged in.', 'success');
  };

  const handleSignupSuccess = (response) => {
    setUser(response.user);
    setAuthToken(response.tokens.access);
    setCurrentPage('home');
    showAlert('Welcome to EcoNext! Your account has been created.', 'success');
  };

  const handleLogout = () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('user');
    setUser(null);
    setAuthToken(null);
    setCart([]);
    setCurrentPage('home');
    showAlert('You have been logged out.', 'success');
  };

  const loadProducts = async () => {
    setLoading(true);
    try {
      const data = await apiService.getProducts(1, 50);
      if (data.status === 'success') {
        setProducts(data.products);
        // Set featured products (randomly select 5)
        const featured = data.products
          .sort(() => Math.random() - 0.5)
          .slice(0, 5);
        setFeaturedProducts(featured);
      }
    } catch (error) {
      console.error('Error loading products:', error);
      showAlert('Failed to load products', 'error');
    }
    setLoading(false);
  };

  const loadTrendingProducts = async () => {
    try {
      const data = await apiService.getTrendingProducts();
      if (data.status === 'success') {
        setTrendingProducts(data.trending_products);
      }
    } catch (error) {
      console.error('Error loading trending:', error);
    }
  };

  const handleSearch = async (e) => {
    e.preventDefault();
    const query = e.target.querySelector('.search-input').value;
    
    if (!query.trim()) return;

    setLoading(true);
    try {
      const data = await apiService.intentSearch(query);
      if (data.status === 'success') {
        setSearchResults(data.results);
        setCurrentPage('search');
      }
    } catch (error) {
      showAlert('Search failed: ' + error.message, 'error');
    }
    setLoading(false);
  };

  const handleAddToCart = (product) => {
    const existingItem = cart.find(item => item.id === product.id);
    
    if (existingItem) {
      setCart(cart.map(item =>
        item.id === product.id
          ? { ...item, quantity: item.quantity + 1 }
          : item
      ));
    } else {
      setCart([...cart, { ...product, quantity: 1 }]);
    }
    
    showAlert(`${product.name} added to cart!`, 'success');
  };

  const handleRemoveFromCart = (productId) => {
    setCart(cart.filter(item => item.id !== productId));
    showAlert('Item removed from cart', 'success');
  };

  const showAlert = (message, type = 'info') => {
    setAlert({ message, type });
    setTimeout(() => setAlert(null), 3000);
  };

  const cartTotal = cart.reduce((sum, item) => sum + (parseFloat(item.current_price) * item.quantity), 0);

  return (
    <div className="App">
      {/* Header */}
      <header>
        <nav>
          <div className="logo" onClick={() => setCurrentPage('home')} style={{cursor: 'pointer'}}>
            <Leaf size={24} style={{display: 'inline-block', marginRight: '8px'}} />
            EcoNext
          </div>
          
          <form className="search-bar" onSubmit={handleSearch}>
            <input
              type="text"
              className="search-input"
              placeholder="Search eco-friendly products..."
            />
            <button type="submit">Search</button>
          </form>

          <ul className="nav-menu">
            <li><a onClick={() => setCurrentPage('home')}>Home</a></li>
            <li><a onClick={() => setCurrentPage('trending')}>Trending</a></li>
            <li><a onClick={() => setCurrentPage('cart')}>🛒 Cart ({cart.length})</a></li>
            
            {user ? (
              <>
                <li><a onClick={() => setCurrentPage('profile')}>👤 {user.username}</a></li>
                <li><a onClick={handleLogout} style={{color: '#EF4444'}}>Logout</a></li>
              </>
            ) : (
              <>
                <li><a onClick={() => setCurrentPage('login')}>Login</a></li>
                <li><a onClick={() => setCurrentPage('signup')}>Sign up</a></li>
              </>
            )}
          </ul>
        </nav>
      </header>

      {/* Alerts */}
      {alert && (
        <motion.div 
          className={`alert alert-${alert.type}`}
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: 50 }}
        >
          {alert.message}
        </motion.div>
      )}

      {/* Main Content */}
      <div className="container">
        {/* Authentication Pages */}
        {currentPage === 'login' && (
          <LoginPage 
            onLoginSuccess={handleLoginSuccess}
            onSwitchPage={setCurrentPage}
          />
        )}

        {currentPage === 'signup' && (
          <SignupPage 
            onSignupSuccess={handleSignupSuccess}
            onSwitchPage={setCurrentPage}
          />
        )}

        {/* Home Page */}
        {currentPage === 'home' && (
          <>
            <HeroSection onExplore={() => {
              const productsSection = document.querySelector('.products-section');
              if (productsSection) {
                productsSection.scrollIntoView({ behavior: 'smooth' });
              }
            }} />

            {/* Featured Carousel */}
            {featuredProducts.length > 0 && (
              <motion.div 
                className="carousel-container"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
              >
                <AnimatePresence mode="wait">
                  <motion.div
                    key={carouselIndex}
                    className="carousel-slide"
                    initial={{ opacity: 0, x: 100 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -100 }}
                    transition={{ duration: 0.5 }}
                    style={{
                      background: `linear-gradient(135deg, ${['#10B981', '#3B82F6', '#F59E0B', '#EF4444', '#8B5CF6'][carouselIndex % 5]} 0%, ${['#059669', '#1E40AF', '#D97706', '#DC2626', '#7C3AED'][carouselIndex % 5]} 100%)`
                    }}
                  >
                    <div className="carousel-content">
                      <h2>Featured Product</h2>
                      <h3 style={{color: 'white', marginBottom: '1rem'}}>{featuredProducts[carouselIndex].name}</h3>
                      <p style={{color: 'rgba(255,255,255,0.9)'}}>{featuredProducts[carouselIndex].description}</p>
                      <div style={{display: 'flex', gap: '1rem'}}>
                        <AnimatedButton 
                          onClick={() => handleAddToCart(featuredProducts[carouselIndex])}
                          variant="primary"
                        >
                          Add to Cart
                        </AnimatedButton>
                        <AnimatedButton 
                          onClick={() => setCurrentPage(`product-${featuredProducts[carouselIndex].id}`)}
                          variant="outline"
                        >
                          View Details
                        </AnimatedButton>
                      </div>
                    </div>
                    <img 
                      src="https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=500&h=300&fit=crop"
                      alt="Featured"
                      className="carousel-image"
                    />
                  </motion.div>
                </AnimatePresence>

                {/* Carousel Controls */}
                <div className="carousel-controls">
                  {featuredProducts.map((_, idx) => (
                    <motion.div
                      key={idx}
                      className={`carousel-dot ${idx === carouselIndex ? 'active' : ''}`}
                      onClick={() => setCarouselIndex(idx)}
                      whileHover={{ scale: 1.2 }}
                      whileTap={{ scale: 0.9 }}
                    />
                  ))}
                </div>
              </motion.div>
            )}

            {/* Trending Products Section */}
            {trendingProducts.length > 0 && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                style={{ marginBottom: '3rem' }}
              >
                <div className="section-header">
                  <h2>🔥 Trending Now</h2>
                  <a className="view-all" onClick={() => setCurrentPage('trending')}>View All</a>
                </div>
                <div className="product-grid">
                  {trendingProducts.slice(0, 8).map((item, idx) => (
                    <motion.div
                      key={idx}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: idx * 0.05 }}
                    >
                      <ProductCard
                        product={item.product}
                        onAddCart={handleAddToCart}
                        onViewDetails={() => setCurrentPage(`product-${item.product.id}`)}
                      />
                    </motion.div>
                  ))}
                </div>
              </motion.div>
            )}

            {/* All Products Section */}
            {products.length > 0 && (
              <motion.div 
                className="products-section"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.6 }}
              >
                <div className="section-header">
                  <h2>All Eco-Friendly Products</h2>
                  <span style={{color: 'var(--gray-600)'}}>Showing {products.length} products</span>
                </div>
                <div className="product-grid">
                  {products.map((product, idx) => (
                    <motion.div
                      key={product.id}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: (idx % 8) * 0.05 }}
                    >
                      <ProductCard
                        product={product}
                        onAddCart={handleAddToCart}
                        onViewDetails={() => setCurrentPage(`product-${product.id}`)}
                      />
                    </motion.div>
                  ))}
                </div>
              </motion.div>
            )}

            {loading && (
              <motion.div 
                className="loading-container"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
              >
                <div className="loading"></div>
                <span className="loading-text">Loading products...</span>
              </motion.div>
            )}
          </>
        )}

        {/* Product Detail Page */}
        {currentPage.startsWith('product-') && !loading && (
          <ProductDetailView
            productId={parseInt(currentPage.split('-')[1])}
            onAddToCart={handleAddToCart}
            onBack={() => setCurrentPage('home')}
          />
        )}

        {/* Search Results */}
        {currentPage === 'search' && searchResults && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
          >
            <AnimatedButton onClick={() => setCurrentPage('home')} variant="outline">
              ← Back
            </AnimatedButton>
            <h2 style={{marginTop: '2rem', marginBottom: '1.5rem'}}>Search Results</h2>
            {Object.entries(searchResults).map(([category, items]) => (
              <motion.div 
                key={category}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                style={{marginBottom: '3rem'}}
              >
                <h3 style={{marginBottom: '1.5rem', color: 'var(--primary)'}}>{category}</h3>
                <div className="product-grid">
                  {items.map(item => (
                    <ProductCard
                      key={item.product.id}
                      product={item.product}
                      onAddCart={handleAddToCart}
                      onViewDetails={() => setCurrentPage(`product-${item.product.id}`)}
                    />
                  ))}
                </div>
              </motion.div>
            ))}
          </motion.div>
        )}

        {/* Trending Page */}
        {currentPage === 'trending' && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
          >
            <AnimatedButton onClick={() => setCurrentPage('home')} variant="outline">
              ← Back
            </AnimatedButton>
            <h2 style={{marginTop: '2rem', marginBottom: '1.5rem'}}>🔥 Trending Products</h2>
            <div className="product-grid">
              {trendingProducts.map((item, idx) => (
                <motion.div
                  key={idx}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: idx * 0.05 }}
                >
                  <ProductCard
                    product={item.product}
                    onAddCart={handleAddToCart}
                    onViewDetails={() => setCurrentPage(`product-${item.product.id}`)}
                  />
                </motion.div>
              ))}
            </div>
          </motion.div>
        )}

        {/* Cart Page */}
        {currentPage === 'cart' && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
          >
            <AnimatedButton onClick={() => setCurrentPage('home')} variant="outline">
              ← Continue Shopping
            </AnimatedButton>
            <h2 style={{marginTop: '2rem', marginBottom: '1.5rem'}}>🛒 Shopping Cart</h2>
            {cart.length === 0 ? (
              <motion.div 
                className="empty-state"
                initial={{ scale: 0.9 }}
                animate={{ scale: 1 }}
              >
                <p style={{fontSize: '3rem', marginBottom: '1rem'}}>🛒</p>
                <p>Your cart is empty</p>
                <AnimatedButton onClick={() => setCurrentPage('home')} variant="primary" style={{marginTop: '1rem'}}>
                  Continue Shopping
                </AnimatedButton>
              </motion.div>
            ) : (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
              >
                <div style={{background: 'white', borderRadius: '12px', padding: '1.5rem', marginBottom: '2rem', boxShadow: 'var(--shadow-md)'}}>
                  {cart.map((item, idx) => (
                    <motion.div 
                      key={item.id}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: idx * 0.05 }}
                      style={{display: 'flex', justifyContent: 'space-between', padding: '1rem', borderBottom: idx < cart.length - 1 ? '1px solid var(--border)' : 'none'}}
                    >
                      <div>
                        <h3 style={{margin: 0, marginBottom: '0.5rem'}}>{item.name}</h3>
                        <p style={{margin: 0, color: 'var(--gray-600)'}}>${item.current_price}</p>
                      </div>
                      <AnimatedButton 
                        onClick={() => handleRemoveFromCart(item.id)}
                        variant="outline"
                        size="sm"
                      >
                        Remove
                      </AnimatedButton>
                    </motion.div>
                  ))}
                </div>

                <div style={{background: 'white', borderRadius: '12px', padding: '2rem', boxShadow: 'var(--shadow-md)'}}>
                  <div style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--primary)', marginBottom: '1.5rem', textAlign: 'center'}}>
                    Total: ${cartTotal.toFixed(2)}
                  </div>
                  <AnimatedButton 
                    onClick={() => {
                      if (!authToken) {
                        showAlert('Please login to checkout', 'error');
                        setCurrentPage('login');
                        return;
                      }
                      setCurrentPage('checkout');
                    }} 
                    variant="primary" 
                    size="lg" 
                    style={{width: '100%', justifyContent: 'center'}}
                  >
                    💳 Proceed to Checkout
                  </AnimatedButton>
                </div>
              </motion.div>
            )}
          </motion.div>
        )}

        {/* Checkout Page */}
        {currentPage === 'checkout' && (
          <CheckoutPage
            cart={cart}
            onBack={() => setCurrentPage('cart')}
            onOrderSuccess={(order) => {
              setCart([]);
              showAlert('Order placed successfully!', 'success');
              setTimeout(() => setCurrentPage('home'), 2000);
            }}
            authToken={authToken}
          />
        )}

        {/* Profile Page */}
        {currentPage === 'profile' && (
          <ProfilePage
            user={user}
            authToken={authToken}
            onBack={() => setCurrentPage('home')}
          />
        )}
      </div>
    </div>
  );
}

export default App;
