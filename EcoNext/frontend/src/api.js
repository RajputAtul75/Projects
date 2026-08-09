// API Configuration and Service
// All API calls go through this centralized service

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://127.0.0.1:8000/api';

const handleResponse = async (res) => {
  if (!res.ok && res.status >= 500) {
    throw new Error(`Server error: ${res.status}`);
  }
  return res.json();
};

const normalizeListResponse = (response) => {
  if (Array.isArray(response)) return response;
  if (Array.isArray(response?.results)) return response.results;
  if (Array.isArray(response?.data)) return response.data;
  return [];
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
  getProducts(arg1 = 1, arg2 = 12) {
    let query = '';

    if (typeof arg1 === 'object' && arg1 !== null) {
      const params = new URLSearchParams();
      Object.entries(arg1).forEach(([key, value]) => {
        if (value === undefined || value === null || value === '') return;
        if (Array.isArray(value)) {
          value.forEach((item) => params.append(key, item));
        } else {
          params.append(key, value);
        }
      });
      query = params.toString();
    } else {
      query = new URLSearchParams({ page: arg1, per_page: arg2 }).toString();
    }

    return fetch(`${API_BASE_URL}/products/?${query}`)
      .then(handleResponse);
  },

  getProductDetail(productId) {
    return fetch(`${API_BASE_URL}/products/${productId}/`)
      .then(handleResponse);
  },

  // Personalization
  getAgeGroups() {
    return fetch(`${API_BASE_URL}/products/age-groups/`)
      .then(handleResponse)
      .then(normalizeListResponse);
  },

  getGenderCategories() {
    return fetch(`${API_BASE_URL}/products/gender-categories/`)
      .then(handleResponse)
      .then(normalizeListResponse);
  },

  async getCategories() {
    const response = await fetch(`${API_BASE_URL}/products/categories/`).then(handleResponse);
    if (Array.isArray(response)) {
      return response;
    }
    if (response?.categories && typeof response.categories === 'object') {
      return Object.keys(response.categories).map((name, idx) => ({ id: idx + 1, name }));
    }
    return [];
  },

  getEcoTags() {
    return fetch(`${API_BASE_URL}/products/eco-tags/`)
      .then(handleResponse)
      .then(normalizeListResponse);
  },

  getRecommendations() {
    return fetch(`${API_BASE_URL}/products/recommendations/`, {
        headers: {'Authorization': `Bearer ${localStorage.getItem('authToken')}`}
    }).then(handleResponse);
  },

  getUserPreferences() {
    return fetch(`${API_BASE_URL}/personalization/preferences/`, {
        headers: {'Authorization': `Bearer ${localStorage.getItem('authToken')}`}
    })
      .then(handleResponse)
      .then(normalizeListResponse);
  },

  async updateUserPreferences(preferences) {
    const token = localStorage.getItem('authToken');
    const existing = await this.getUserPreferences();

    if (Array.isArray(existing) && existing.length > 0) {
      return fetch(`${API_BASE_URL}/personalization/preferences/${existing[0].id}/`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(preferences)
      }).then(handleResponse);
    }

    return fetch(`${API_BASE_URL}/personalization/preferences/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify(preferences)
    }).then(handleResponse);
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
  },

  ecoAiRecommend(query) {
    return fetch(`${API_BASE_URL}/copilot/`, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ query })
    })
      .then(handleResponse);
  },

  copilotRecommend(query) {
    return this.ecoAiRecommend(query);
  }
};
