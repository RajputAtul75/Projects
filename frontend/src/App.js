import React, { useState, useEffect } from 'react';
import './styles.css';
import './App.css';
import { apiService } from './api';
import LoginPage from './LoginPage';
import SignupPage from './SignupPage';

function App() {
  const [currentPage, setCurrentPage] = useState('home');
  const [products, setProducts] = useState([]);
  const [searchResults, setSearchResults] = useState(null);
  const [cart, setCart] = useState([]);
  const [trendingProducts, setTrendingProducts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [alert, setAlert] = useState(null);
  const [visualSearchOn, setVisualSearchOn] = useState(false);
  const [user, setUser] = useState(null);
  const [authToken, setAuthToken] = useState(localStorage.getItem('authToken'));

  // Load user on mount
  useEffect(() => {
    loadProducts();
    loadTrendingProducts();
    checkUserSession();
  }, []);

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
      const data = await apiService.getProducts();
      if (data.status === 'success') {
        setProducts(data.products);
      }
    } catch (error) {
      console.error('Error loading products:', error);
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

  const handleVisualSearch = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    setLoading(true);
    try {
      const data = await apiService.visualSearch(file);
      if (data.status === 'success') {
        setSearchResults({
          'Visual Search Results': data.results.map(r => ({
            product: r.product,
            similarity_score: r.similarity_score,
            intent_match: `Similarity: ${(r.similarity_score * 100).toFixed(1)}%`
          }))
        });
        setCurrentPage('search');
      }
    } catch (error) {
      showAlert('Visual search failed: ' + error.message, 'error');
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

  const handleCartQuantityChange = (productId, quantity) => {
    if (quantity <= 0) {
      setCart(cart.filter(item => item.id !== productId));
    } else {
      setCart(cart.map(item =>
        item.id === productId
          ? { ...item, quantity }
          : item
      ));
    }
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
            🌿 EcoNext
          </div>
          
          <form className="search-bar" onSubmit={handleSearch}>
            <input
              type="text"
              className="search-input"
              placeholder="🔍 Search products by intent..."
            />
            <button type="submit">Search</button>
          </form>

          <ul className="nav-menu">
            <li><a onClick={() => setCurrentPage('home')}>Home</a></li>
            <li><a onClick={() => setCurrentPage('trending')}>Trending</a></li>
            <li><a onClick={() => setCurrentPage('visual')}>📸 Visual Search</a></li>
            <li><a onClick={() => setCurrentPage('cart')}>🛒 Cart ({cart.length})</a></li>
            
            {user ? (
              <>
                <li><a onClick={() => setCurrentPage('profile')}>👤 {user.username}</a></li>
                <li><a onClick={handleLogout} className="logout-btn">Logout</a></li>
              </>
            ) : (
              <>
                <li><a onClick={() => setCurrentPage('login')} className="auth-btn">Login</a></li>
                <li><a onClick={() => setCurrentPage('signup')} className="auth-btn">Sign up</a></li>
              </>
            )}
          </ul>
        </nav>
      </header>

      {/* Alerts */}
      {alert && (
        <div className={`container`}>
          <div className={`alert alert-${alert.type}`}>
            {alert.message}
          </div>
        </div>
      )}

      {/* Main Content */}
      <div className="container">
        {loading && <div style={{textAlign: 'center', padding: '2rem'}}>⏳ Loading...</div>}

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
        {currentPage === 'home' && !loading && (
          <>
            <div className="hero">
              <h1>🚀 AI-Powered Smart Shopping</h1>
              <p>✨ Price predictions • 🎯 Smart search • 📸 Visual search</p>
            </div>

            {trendingProducts.length > 0 && (
              <div style={{marginBottom: '2rem'}}>
                <h2>🔥 Trending Now</h2>
                <div className="trending-list">
                  {trendingProducts.slice(0, 5).map((item, idx) => (
                    <div key={idx} className="trending-item">
                      <div className="trending-rank">#{idx + 1}</div>
                      <div className="trending-info">
                        <div className="trending-name">{item.product.name}</div>
                        <div className="trending-stats">
                          👁 {item.views} views • 🛒 {item.purchases} purchases
                        </div>
                      </div>
                      <div style={{fontSize: '1.1rem', fontWeight: 'bold', color: '#4CAF50'}}>
                        ${item.product.current_price}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <h2>Available Products</h2>
            <div className="products-grid">
              {products.map(product => (
                <ProductCard
                  key={product.id}
                  product={product}
                  onAddToCart={handleAddToCart}
                  onViewDetails={() => setCurrentPage(`product-${product.id}`)}
                />
              ))}
            </div>
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
          <>
            <button onClick={() => setCurrentPage('home')} className="btn btn-outline">
              ← Back
            </button>
            <h2>Search Results</h2>
            {Object.entries(searchResults).map(([category, items]) => (
              <div key={category} className="category-section">
                <div className="category-title">{category}</div>
                <div className="category-products">
                  {items.map(item => (
                    <ProductCard
                      key={item.product.id}
                      product={item.product}
                      onAddToCart={handleAddToCart}
                      onViewDetails={() => setCurrentPage(`product-${item.product.id}`)}
                    />
                  ))}
                </div>
              </div>
            ))}
          </>
        )}

        {/* Trending Page */}
        {currentPage === 'trending' && (
          <>
            <button onClick={() => setCurrentPage('home')} className="btn btn-outline">
              ← Back
            </button>
            <h2>🔥 Trending Products</h2>
            <div className="products-grid">
              {trendingProducts.map((item, idx) => (
                <ProductCard
                  key={idx}
                  product={item.product}
                  onAddToCart={handleAddToCart}
                  onViewDetails={() => setCurrentPage(`product-${item.product.id}`)}
                />
              ))}
            </div>
          </>
        )}

        {/* Visual Search */}
        {currentPage === 'visual' && (
          <>
            <button onClick={() => setCurrentPage('home')} className="btn btn-outline">
              ← Back
            </button>
            <div className="visual-search-container">
              <h2>📸 Visual Search - Upload an Image</h2>
              <div className="upload-area" onClick={() => document.getElementById('visualInput').click()}>
                <p>📤 Click to upload or drag and drop</p>
                <input
                  id="visualInput"
                  type="file"
                  accept="image/*"
                  onChange={handleVisualSearch}
                />
              </div>
            </div>
          </>
        )}

        {/* Cart Page */}
        {currentPage === 'cart' && (
          <>
            <button onClick={() => setCurrentPage('home')} className="btn btn-outline">
              ← Continue Shopping
            </button>
            <h2>🛒 Shopping Cart</h2>
            {cart.length === 0 ? (
              <div style={{textAlign: 'center', padding: '2rem'}}>
                <p>Your cart is empty</p>
                <button onClick={() => setCurrentPage('home')} className="btn btn-primary">
                  Continue Shopping
                </button>
              </div>
            ) : (
              <>
                <div style={{background: 'white', borderRadius: '8px', padding: '1rem', marginBottom: '2rem'}}>
                  {cart.map(item => (
                    <div key={item.id} className="cart-item" style={{flexDirection: 'column', alignItems: 'flex-start'}}>
                      <div style={{display: 'flex', justifyContent: 'space-between', width: '100%'}}>
                        <div>
                          <h3>{item.name}</h3>
                          <p>${item.current_price} each</p>
                        </div>
                        <button
                          onClick={() => handleRemoveFromCart(item.id)}
                          className="btn btn-outline"
                          style={{flex: 'none'}}
                        >
                          Remove
                        </button>
                      </div>
                      <div className="cart-item-quantity" style={{marginTop: '0.5rem'}}>
                        <button onClick={() => handleCartQuantityChange(item.id, item.quantity - 1)}>−</button>
                        <span style={{margin: '0 0.5rem'}}>{item.quantity}</span>
                        <button onClick={() => handleCartQuantityChange(item.id, item.quantity + 1)}>+</button>
                      </div>
                    </div>
                  ))}
                </div>

                <div style={{background: 'white', borderRadius: '8px', padding: '2rem', marginBottom: '2rem'}}>
                  <div className="cart-total">
                    Total: ${cartTotal.toFixed(2)}
                  </div>
                  <button className="btn btn-primary" style={{width: '100%'}}>
                    💳 Proceed to Checkout
                  </button>
                </div>
              </>
            )}
          </>
        )}
      </div>
    </div>
  );
}

// Product Card Component
function ProductCard({ product, onAddToCart, onViewDetails }) {
  const [prediction, setPrediction] = useState(null);

  useEffect(() => {
    // Load price prediction
    const loadPrediction = async () => {
      try {
        const data = await apiService.getPricePrediction(product.id);
        if (data.status === 'success' && data.prediction) {
          setPrediction(data.prediction);
        }
      } catch (error) {
        console.error('Error loading prediction:', error);
      }
    };
    loadPrediction();
  }, [product.id]);

  return (
    <div className="product-card">
      {product.image_url && (
        <img src={product.image_url} alt={product.name} className="product-image" />
      )}
      <div className="product-info">
        <div className="product-name">{product.name}</div>
        <div className="product-category">{product.category.name}</div>
        <div className="product-price">${product.current_price}</div>

        {prediction && (
          <div className={`price-prediction ${prediction.recommendation === 'best_price' ? 'best' : 'wait'}`}>
            {prediction.recommendation === 'best_price' && '🟢 Best Price'}
            {prediction.recommendation === 'wait' && '🟡 Wait - Price Drop Likely'}
            {prediction.recommendation === 'neutral' && '⚪ Neutral'}
          </div>
        )}

        <div className="product-actions">
          <button onClick={onViewDetails} className="btn btn-secondary">View</button>
          <button onClick={() => onAddToCart(product)} className="btn btn-primary">Add</button>
        </div>
      </div>
    </div>
  );
}

// Product Detail View Component
function ProductDetailView({ productId, onAddToCart, onBack }) {
  const [product, setProduct] = useState(null);
  const [prediction, setPrediction] = useState(null);
  const [loading, setLoading] = useState(true);

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

  if (loading) return <div>Loading...</div>;

  if (!product) return <div>Product not found</div>;

  return (
    <div>
      <button onClick={onBack} className="btn btn-outline">← Back</button>
      
      <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', marginTop: '2rem'}}>
        <div>
          {product.image_url && (
            <img src={product.image_url} alt={product.name} style={{borderRadius: '8px'}} />
          )}
        </div>

        <div>
          <h1>{product.name}</h1>
          <p style={{color: '#666', marginBottom: '1rem'}}>{product.category.name}</p>

          <h2 style={{fontSize: '2rem', color: '#4CAF50', marginBottom: '1rem'}}>
            ${product.current_price}
          </h2>

          {prediction && (
            <div style={{
              background: prediction.recommendation === 'best_price' ? '#c8e6c9' : '#ffe0b2',
              padding: '1rem',
              borderRadius: '8px',
              marginBottom: '1rem'
            }}>
              <strong>📊 7-Day Price Prediction:</strong>
              {prediction.recommendation === 'best_price' && (
                <p>🟢 This is a great price to buy! Price is likely to increase.</p>
              )}
              {prediction.recommendation === 'wait' && (
                <p>🟡 Price may drop further. Consider waiting for a few days.</p>
              )}
              <p>Confidence: {(prediction.confidence_score * 100).toFixed(1)}%</p>
            </div>
          )}

          <p style={{marginBottom: '2rem'}}>{product.description}</p>

          <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem'}}>
            <button onClick={() => onAddToCart(product)} className="btn btn-primary" style={{padding: '1rem'}}>
              🛒 Add to Cart
            </button>
            <button onClick={onBack} className="btn btn-outline">Back</button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
