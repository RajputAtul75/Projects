# EcoNext - AI-Powered E-Commerce Platform

EcoNext is a next-generation e-commerce platform featuring AI-driven price predictions, visual search, smart intent-based search, and real-time analytics.

## 🚀 Features

### 1. **Buy or Wait Price Predictor** 🎯
- Linear Regression ML model predicts price trends for next 7 days
- Shows recommendations: 🟢 Best Price | 🟡 Wait (Price Drop Likely)
- Analyzes historical pricing data to provide confidence scores
- Helps users make optimal purchase decisions

### 2. **Visual Search (Snap & Shop)** 📸
- Upload product images to find similar items
- CNN (ResNet50) extracts image features
- Cosine similarity matching against product catalog
- Returns top 10 visually similar products

### 3. **Smart Intent-Based Search** 🧠
- TF-IDF powered semantic search
- Query like "Gym" returns: athletic shoes, water bottles, yoga mats, dumbbells
- Category-based recommendations
- Intent explanation for each result

### 4. **Real-Time Analytics Dashboard** 📊
- Trending products in real-time
- Active user count, search trends, purchase activity
- Built for scalability with caching

### 5. **Complete E-Commerce System**
- User authentication & authorization
- Shopping cart with real-time updates
- Order management with status tracking
- Product catalog with categories
- User activity logging

### 6. **Scalability & Performance**
- Redis caching for frequently accessed data
- Database indexing for fast queries
- RESTful API architecture
- CORS enabled for frontend integration

---

## 🛠️ Tech Stack

### Backend
- **Django 5.1**: Web framework
- **Django REST Framework**: API development
- **Scikit-learn**: ML model training
- **TensorFlow/PyTorch**: Deep learning (visual search)
- **PostgreSQL/SQLite**: Primary database
- **Redis**: Caching layer
- **Celery**: Background task queue (optional)

### Frontend
- **HTML5**: Semantic markup
- **CSS3**: Modern styling
- **Vanilla JavaScript**: No framework, hence maximum flexibility
- **Fetch API**: API communication

### ML/AI
- **Scikit-learn LinearRegression**: Price prediction
- **ResNet50**: Image feature extraction
- **TF-IDF**: Intent-based search
- **Cosine Similarity**: Visual similarity matching

---

## 📋 Setup Instructions

### Backend Setup

#### 1. Install Dependencies
```bash
cd backend
pip install -r requirements.txt
```

#### 2. Apply Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

#### 3. Seed Sample Data
```bash
python manage.py seed_data
```
This creates:
- 5 product categories
- 10 sample products
- 60 days of price history per product
- ML predictions for each product

#### 4. Create Superuser (Admin)
```bash
python manage.py createsuperuser
```

#### 5. Run Development Server
```bash
python manage.py runserver
```
Server runs on: `http://127.0.0.1:8000`

### Frontend Setup

#### 1. Install Dependencies
```bash
cd frontend
npm install
```

#### 2. Start Development Server
```bash
npm start
```
App runs on: `http://localhost:3000`

---

## 🌐 API Endpoints

### Products
- `GET /api/products/` - List all products
- `GET /api/products/<id>/` - Get product detail with prediction
- `GET /api/products/trending/` - Get trending products

### Search
- `GET /api/products/search/intent/?q=gym` - Intent-based search
- `POST /api/products/search/visual/` - Visual search (image upload)
- `GET /api/products/categories/` - Browse by category

### ML Features
- `GET /api/products/<id>/prediction/` - 7-day price prediction

### Shopping Cart (Auth Required)
- `GET /api/cart/` - Get cart
- `POST /api/cart/add/` - Add to cart
- `PATCH /api/cart/item/<id>/` - Update quantity
- `DELETE /api/cart/item/<id>/delete/` - Remove item
- `DELETE /api/cart/clear/` - Clear cart

### Orders (Auth Required)
- `POST /api/orders/create/` - Create order
- `GET /api/orders/` - Get user's orders
- `GET /api/orders/<id>/` - Get order detail
- `PATCH /api/orders/<id>/status/` - Update status (admin only)

### Analytics
- `GET /api/products/search/trending/` - Trending searches

---

## 🎨 Frontend Features

### Navigation
- **Home**: Product listing with trending
- **Search**: Real-time intent-based search
- **Visual Search**: Upload image to find similar products
- **Cart**: Shopping cart with quantity controls
- **Product Detail**: View full product info with price prediction

### Price Prediction Display
- 🟢 **Best Price**: Price likely to increase, buy now
- 🟡 **Wait**: Price drop likely, wait a few days
- ⚪ **Neutral**: Price stable

### Search Results
- Category-grouped results
- Intent-based recommendations
- Similarity scores for visual search

---

## 🧪 Testing the Features

### 1. Test Price Prediction
```
1. Go to any product page
2. See 7-day prediction with recommendation
3. Confidence score shows model accuracy
```

### 2. Test Intent Search
```
Search queries:
- "gym" -> Shows gym shoes, water bottle, yoga mat, dumbbells
- "office" -> Shows desk items, chairs, stationery
- "beach" -> Shows swimwear, sunscreen, flip flops
- "cooking" -> Shows knives, pans, cutting boards
```

### 3. Test Visual Search
```
1. Click "📸 Visual Search"
2. Upload product image
3. System returns visually similar products
```

### 4. Test Shopping
```
1. Add products to cart
2. Adjust quantities
3. View total price
4. Proceed to checkout (ready for implementation)
```

---

## 📊 Data Models

### Product
- Name, description, category
- Current price, stock
- Tags (for TF-IDF search)
- Image features (CNN extracted)

### PriceHistory
- Product → Price mapping per day
- Last 60+ days of data for ML

### PricePrediction
- 7-day forecast
- Recommendation (best_price/wait/neutral)
- Confidence score (0-1)

### Cart & Order
- User → Cart mapping
- Cart items with quantities
- Order history with status

---

## 🚀 Deployment

### Production Considerations
1. Use PostgreSQL instead of SQLite
2. Enable HTTPS
3. Set `DEBUG = False`
4. Use environment variables for secrets
5. Configure static file serving with Nginx
6. Use Gunicorn for WSGI server
7. Set up Celery for background tasks
8. Enable Redis caching

---

## 🤝 Contributing

Future enhancements:
- Payment gateway integration (Stripe, PayPal)
- Email notifications
- User reviews and ratings
- Advanced ML: Collaborative filtering
- Mobile app (React Native)
- Admin dashboard (React)

---

## 📜 License

MIT License - Feel free to use this project!

---

## 📞 Support

For issues or questions, please check:
1. Backend logs: `python manage.py runserver`
2. Frontend console: Press F12
3. API responses: Check network tab

---

**Made with ❤️ by EcoNext Team**
