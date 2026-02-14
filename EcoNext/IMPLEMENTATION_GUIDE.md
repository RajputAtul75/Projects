# EcoNext Implementation Guide

## 🏗️ Project Architecture

```
EcoNext/
├── backend/
│   ├── econext/              # Main Django config
│   │   ├── settings.py       # Django settings (includes REST framework config)
│   │   ├── urls.py           # Main URL router
│   │   └── wsgi.py           # WSGI entry point
│   │
│   ├── products/             # Product management app
│   │   ├── models.py         # Product, Category, PriceHistory, ProductSearch models
│   │   ├── api_views.py      # Product API endpoints
│   │   ├── serializers.py    # DRF serializers
│   │   ├── urls.py           # Product URLs
│   │   └── management/
│   │       └── commands/
│   │           └── seed_data.py  # Database seeding script
│   │
│   ├── accounts/             # User authentication
│   │   ├── models.py         # UserProfile, ActivityLog models
│   │   └── views.py          # Auth views (to implement)
│   │
│   ├── shop_cart/            # Shopping cart
│   │   ├── models.py         # Cart, CartItem models
│   │   ├── api_views.py      # Cart API endpoints
│   │   └── serializers.py    # Cart serializers
│   │
│   ├── order_service/        # Order management
│   │   ├── models.py         # Order, OrderItem models
│   │   └── views.py          # Order views (in shop_cart/api_views.py)
│   │
│   ├── site_analytics/       # Analytics & trending
│   │   ├── models.py         # DailyStats, TrendingProduct models
│   │   └── signals.py        # Event tracking (to implement)
│   │
│   ├── ml_engine/            # ML models & algorithms
│   │   ├── models.py         # PricePrediction, ImageFeatures, TFIDFIndex
│   │   ├── price_predictor.py     # Linear Regression for price prediction
│   │   ├── visual_search.py       # ResNet50 CNN for visual search
│   │   ├── intent_search.py       # TF-IDF for semantic search
│   │   └── api_views.py      # ML API endpoints
│   │
│   ├── requirements.txt      # Python dependencies
│   ├── manage.py             # Django CLI
│   ├── db.sqlite3            # SQLite database
│   └── .env.example          # Environment variables template
│
└── frontend/
    ├── public/
    │   ├── index.html        # HTML entry point
    │   ├── favicon.ico
    │   └── manifest.json
    │
    ├── src/
    │   ├── App.js            # Main app component with all pages
    │   ├── api.js            # Centralized API service
    │   ├── styles.css        # Global styles & component styles
    │   ├── App.css           # App-specific styles
    │   ├── index.js          # React entry point
    │   ├── index.css         # Base styles
    │   └── ...
    │
    ├── package.json          # Frontend dependencies
    ├── .env.example          # Environment template
    └── node_modules/         # Dependencies (installed)
```

---

## 🎯 Core Features Implementation

### 1. Price Predictor 🎯

**File**: `ml_engine/price_predictor.py`

**How it works**:
```
1. Get 60 days of historical prices for product
2. Train Linear Regression model: X = [days], y = [prices]
3. Normalize data with StandardScaler
4. Predict next 7 days
5. Compare average future price vs current price
6. Generate recommendation:
   - If future_price < current_price by 5%+ → 🟡 Wait
   - If future_price > current_price by 5%+ → 🟢 Best Price
   - Otherwise → ⚪ Neutral
```

**API Endpoint**:
```
GET /api/products/<id>/prediction/

Response:
{
  "status": "success",
  "prediction": {
    "day1_price": 49.82,
    "day2_price": 50.15,
    ...
    "day7_price": 52.30,
    "recommendation": "best_price",
    "confidence_score": 0.87
  }
}
```

### 2. Visual Search 📸

**File**: `ml_engine/visual_search.py`

**How it works**:
```
1. User uploads image
2. ResNet50 CNN extracts 2048-dimensional feature vector
3. Compare with stored features of all products
4. Calculate cosine similarity
5. Return top 10 most similar products
```

**API Endpoint**:
```
POST /api/products/search/visual/
Content-Type: multipart/form-data

Parameters:
- image: image_file (multipart)

Response:
{
  "status": "success",
  "results": [
    {
      "product": {...},
      "similarity_score": 0.92
    },
    ...
  ]
}
```

### 3. Intent-Based Search 🧠

**File**: `ml_engine/intent_search.py`

**How it works**:
```
1. Build TF-IDF matrix from all products:
   - Document = product name + category + tags
   - Features = word frequency scores
   
2. Query transformation:
   - Convert query to same TF-IDF space
   - Map to product intents (hardcoded mapping)
   
3. Ranking:
   - Calculate cosine similarity
   - Rank by similarity score
   - Group by category
   
4. Examples:
   - "gym" → "Dumbbells", "Yoga Mat", "Water Bottle"
   - "office" → "Desk", "Chair", "Monitor"
```

**API Endpoint**:
```
GET /api/products/search/intent/?q=gym

Response:
{
  "status": "success",
  "query": "gym",
  "results": {
    "Fitness": [
      {
        "product": {...},
        "similarity_score": 0.85,
        "intent_match": "Direct match: gym"
      },
      ...
    ]
  }
}
```

### 4. Cart Management 🛒

**Files**: 
- `shop_cart/models.py` - Cart, CartItem
- `shop_cart/api_views.py` - Cart endpoints

**Flow**:
```
1. User adds product to cart
   → Create/update CartItem
   → Log activity
   → Return updated cart
   
2. Cart persists in DB (per user)
3. Quantity can be updated
4. Items can be removed
5. Cart can be cleared
```

**API Endpoints**:
```
GET /api/cart/                    # Get user's cart
POST /api/cart/add/               # Add item
PATCH /api/cart/item/<id>/        # Update quantity
DELETE /api/cart/item/<id>/delete/# Remove item
DELETE /api/cart/clear/           # Clear cart
```

### 5. Order Management 📦

**Flow**:
```
1. User creates order from cart
2. System validates cart not empty
3. Create Order with shipping info
4. Copy CartItems to OrderItems
5. Clear cart
6. Return confirmation
```

**API Endpoints**:
```
POST /api/orders/create/          # Create order
GET /api/orders/                  # List user orders
GET /api/orders/<id>/             # Get order detail
PATCH /api/orders/<id>/status/    # Update status (admin)
```

### 6. Trending & Analytics 📊

**Model**: `site_analytics/models.py`

**Data Tracked**:
- Daily active users
- Product views per day
- Search queries
- Purchase count
- Trending products

**API Endpoints**:
```
GET /api/products/trending/       # Top trending products
GET /api/products/search/trending/# Top search queries
```

---

## 🎨 Frontend Architecture

### Single-Page App (SPA) Structure

**Main Component**: `App.js`

**State Management** (React Hooks):
```javascript
const [currentPage, setCurrentPage] = useState('home')
const [products, setProducts] = useState([])
const [cart, setCart] = useState([])
const [searchResults, setSearchResults] = useState(null)
const [trendingProducts, setTrendingProducts] = useState([])
```

**Pages**:
1. **Home** - Product grid + trending
2. **Product Detail** - Full product info + prediction
3. **Search Results** - Category-grouped results
4. **Visual Search** - Image upload interface
5. **Trending** - Top products
6. **Cart** - Checkout interface

### Component Flow

```
App
├── Header (Navigation + Search)
├── Alert (Message display)
└── Pages:
    ├── Home (ProductCard × N)
    ├── ProductDetailView
    ├── SearchResults (CategorySection × N)
    ├── VisualSearchPage
    ├── TrendingPage
    └── CartPage
```

### Styling Approach

**CSS Structure**:
- Global variables (colors, spacing)
- Component-based styles
- Responsive grid layout
- Mobile-first design
- Flexbox/Grid for layouts

**Color Scheme**:
```css
--primary: #4CAF50     /* Green - Action buttons */
--secondary: #2196F3   /* Blue - Secondary actions */
--warning: #FF9800     /* Orange - Wait recommendation */
--success: #4CAF50     /* Green - Success messages */
--danger: #f44336      /* Red - Remove/Delete */
--dark: #1a1a1a        /* Text */
--light: #f5f5f5       /* Backgrounds */
```

---

## 🔄 Data Flow Examples

### Example 1: Price Prediction Display

```
User views product
    ↓
Frontend calls: GET /api/products/<id>/
    ↓
Backend:
  - Fetch product from DB
  - Get latest PricePrediction
  - Return both
    ↓
Frontend displays:
  - Product name, price, image
  - 🟢/🟡/⚪ recommendation
  - Confidence score
  - "Day 1-7" predicted prices
```

### Example 2: Intent Search

```
User types "gym" and searches
    ↓
Frontend calls: GET /api/products/search/intent/?q=gym
    ↓
Backend:
  - Build TF-IDF matrix from products
  - Transform query to TF-IDF space
  - Calculate similarities
  - Group by category
  - Sort by relevance
    ↓
Frontend displays:
  - "Fitness" section → [Yoga Mat, Dumbbells, Water Bottle]
  - "Home & Garden" section → [Yoga Mat Stand]
  - Each showing similarity score
```

### Example 3: Shopping Flow

```
User adds product to cart
    ↓
Frontend: POST /api/cart/add/
    ↓
Backend:
  - Create/update CartItem
  - Log ActivityLog
  - Return updated Cart
    ↓
Frontend:
  - Update cart state
  - Show "Added to cart" alert
  - Update cart count
    ↓
User goes to cart page
    ↓
Frontend displays:
  - All items with quantities
  - Total price: $XX.XX
  - Checkout button (ready for implementation)
```

---

## 📊 Database Schema

### Key Models

```
Product
  ├─ name
  ├─ category (FK: Category)
  ├─ current_price
  ├─ image_url
  ├─ tags (JSON: ["gym", "fitness"])
  ├─ image_features (JSON: CNN features)
  └─ created_at

PriceHistory
  ├─ product (FK)
  ├─ price
  ├─ date (unique per product)

PricePrediction
  ├─ product (FK)
  ├─ day1_price ... day7_price
  ├─ recommendation
  ├─ confidence_score
  └─ prediction_date

Cart
  ├─ user (OneToOne FK)
  └─ items (FK: CartItem)

CartItem
  ├─ cart (FK)
  ├─ product (FK)
  └─ quantity

Order
  ├─ user (FK)
  ├─ status
  ├─ total_price
  ├─ shipping details
  └─ items (FK: OrderItem)

ActivityLog
  ├─ user (FK)
  ├─ action ('view', 'search', 'add_to_cart', 'purchase')
  ├─ product (FK)
  └─ timestamp
```

---

## 🚀 How to Deploy

### Development
```bash
# Backend
cd backend
python manage.py runserver

# Frontend (another terminal)
cd frontend
npm start
```

### Production

**Backend**:
```bash
# Use Gunicorn
gunicorn econext.wsgi

# Or with Nginx proxy
server {
    listen 80;
    location / {
        proxy_pass http://localhost:8000;
    }
}
```

**Frontend**:
```bash
# Build optimized version
npm run build

# Deploy to static host (Netlify, Vercel, GitHub Pages)
```

---

## ✅ Validation Checklist

- [ ] Backend migrations applied
- [ ] Sample data seeded with `python manage.py seed_data`
- [ ] Django server running on 8000
- [ ] Frontend running on 3000
- [ ] Can view products on home page
- [ ] Price predictions display for products
- [ ] Search works with intent matching
- [ ] Can add items to cart
- [ ] Cart totals calculate correctly
- [ ] No console errors in browser

---

## 🐛 Debugging Tips

### Backend Issues
```bash
# Check migrations
python manage.py showmigrations

# Run specific command
python manage.py seed_data --verbosity=2

# Django shell for testing
python manage.py shell
>>> from products.models import Product
>>> Product.objects.all()
```

### Frontend Issues
```bash
# Check API responses
F12 → Network tab → Check XHR requests

# Console errors
F12 → Console tab → Look for red errors

# CORS issues
Backend response should have:
  Access-Control-Allow-Origin: http://localhost:3000
```

---

## 📝 Future Enhancements

1. **Authentication**
   - User registration/login
   - JWT tokens for API
   - Google/Facebook OAuth

2. **Payment Integration**
   - Stripe checkout
   - PayPal integration
   - Order confirmation & receipt

3. **Advanced ML**
   - Collaborative filtering (user-based)
   - Product recommendations
   - Customer clustering

4. **Real-Time Features**
   - WebSocket for live notifications
   - Real-time inventory updates
   - Live chat support

5. **Admin Dashboard**
   - React admin panel
   - Sales analytics
   - Inventory management

6. **Mobile App**
   - React Native version
   - Push notifications
   - Offline mode

---

**Last Updated**: February 11, 2026
**Status**: ✅ Core features implemented and tested
