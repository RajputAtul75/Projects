// API Configuration and Service
// All API calls go through this centralized service

const API_BASE_URL = 'http://127.0.0.1:8000/api';

const handleResponse = async (res) => {
  if (!res.ok && res.status >= 500) {
    throw new Error(`Server error: ${res.status}`);
  }
  return res.json();
};

export const apiService = {
  // Authentication
  signup(userData) {
    return fetch(`${API_BASE_URL}/auth/signup/`, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(userData)
    })
      .then(handleResponse);
  },

  login(credentials) {
    return fetch(`${API_BASE_URL}/auth/login/`, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(credentials)
    })
      .then(handleResponse);
  },

  logout() {
    return fetch(`${API_BASE_URL}/auth/logout/`, {
      method: 'POST',
      headers: {'Authorization': `Bearer ${localStorage.getItem('authToken')}`}
    })
      .then(handleResponse);
  },

  getCurrentUser() {
    return fetch(`${API_BASE_URL}/auth/current-user/`, {
      headers: {'Authorization': `Bearer ${localStorage.getItem('authToken')}`}
    })
      .then(handleResponse);
  },

  updateProfile(profileData) {
    return fetch(`${API_BASE_URL}/auth/profile/update/`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('authToken')}`
      },
      body: JSON.stringify(profileData)
    })
      .then(handleResponse);
  },

  // Products
  getProducts(page = 1, perPage = 12) {
    return fetch(`${API_BASE_URL}/products/?page=${page}&per_page=${perPage}`)
      .then(handleResponse);
  },

  getProductDetail(productId) {
    return fetch(`${API_BASE_URL}/products/${productId}/`)
      .then(handleResponse);
  },

  // Search
  intentSearch(query) {
    return fetch(`${API_BASE_URL}/products/search/intent/?q=${encodeURIComponent(query)}`)
      .then(handleResponse);
  },

  visualSearch(imageFile) {
    const formData = new FormData();
    formData.append('image', imageFile);
    
    return fetch(`${API_BASE_URL}/products/search/visual/`, {
      method: 'POST',
      body: formData
    })
      .then(handleResponse);
  },

  // Price Prediction
  getPricePrediction(productId) {
    return fetch(`${API_BASE_URL}/products/${productId}/prediction/`)
      .then(handleResponse);
  },

  // Trending
  getTrendingProducts() {
    return fetch(`${API_BASE_URL}/products/trending/`)
      .then(handleResponse);
  },

  // Cart (Authentication required)
  getCart(authToken) {
    return fetch(`${API_BASE_URL}/cart/`, {
      headers: {'Authorization': `Bearer ${authToken}`}
    })
      .then(handleResponse);
  },

  addToCart(productId, quantity, authToken) {
    return fetch(`${API_BASE_URL}/cart/add/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
      },
      body: JSON.stringify({product_id: productId, quantity})
    })
      .then(handleResponse);
  },

  updateCartItem(itemId, quantity, authToken) {
    return fetch(`${API_BASE_URL}/cart/item/${itemId}/`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
      },
      body: JSON.stringify({quantity})
    })
      .then(handleResponse);
  },

  removeFromCart(itemId, authToken) {
    return fetch(`${API_BASE_URL}/cart/item/${itemId}/delete/`, {
      method: 'DELETE',
      headers: {'Authorization': `Bearer ${authToken}`}
    })
      .then(handleResponse);
  },

  clearCart(authToken) {
    return fetch(`${API_BASE_URL}/cart/clear/`, {
      method: 'DELETE',
      headers: {'Authorization': `Bearer ${authToken}`}
    })
      .then(handleResponse);
  },

  // Orders
  createOrder(shippingData, authToken) {
    return fetch(`${API_BASE_URL}/orders/create/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
      },
      body: JSON.stringify({shipping: shippingData})
    })
      .then(handleResponse);
  },

  getOrders(authToken) {
    return fetch(`${API_BASE_URL}/orders/`, {
      headers: {'Authorization': `Bearer ${authToken}`}
    })
      .then(handleResponse);
  },

  getOrderDetail(orderId, authToken) {
    return fetch(`${API_BASE_URL}/orders/${orderId}/`, {
      headers: {'Authorization': `Bearer ${authToken}`}
    })
      .then(handleResponse);
  }
};
