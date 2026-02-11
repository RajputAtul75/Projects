from django.core.management.base import BaseCommand
from django.utils import timezone
from products.models import Category, Product, PriceHistory
from ml_engine.models import PricePrediction
import random
from datetime import timedelta

class Command(BaseCommand):
    help = 'Seed database with sample products and data'

    def handle(self, *args, **options):
        self.stdout.write("🌱 Seeding database with sample data...")

        # Create categories
        categories_data = [
            {'name': 'Electronics', 'description': 'Electronic devices and gadgets'},
            {'name': 'Fitness', 'description': 'Sports and fitness equipment'},
            {'name': 'Kitchen', 'description': 'Kitchen appliances and tools'},
            {'name': 'Fashion', 'description': 'Clothing and accessories'},
            {'name': 'Home & Garden', 'description': 'Home decor and gardening'},
        ]

        categories = {}
        for cat_data in categories_data:
            cat, created = Category.objects.get_or_create(
                name=cat_data['name'],
                defaults={'description': cat_data['description']}
            )
            categories[cat_data['name']] = cat
            if created:
                self.stdout.write(f"✓ Created category: {cat_data['name']}")

        # Sample products
        products_data = [
            {
                'name': 'Wireless Bluetooth Speaker',
                'category': 'Electronics',
                'description': 'High-quality portable Bluetooth speaker with 360° sound',
                'price': 49.99,
                'tags': ['speaker', 'bluetooth', 'audio', 'portable']
            },
            {
                'name': 'Yoga Mat Premium',
                'category': 'Fitness',
                'description': 'Non-slip TPE yoga mat perfect for all workout styles',
                'price': 29.99,
                'tags': ['yoga', 'fitness', 'exercise', 'gym']
            },
            {
                'name': 'Stainless Steel Water Bottle',
                'category': 'Fitness',
                'description': 'Insulated water bottle keeps drinks cold for 24 hours',
                'price': 24.99,
                'tags': ['bottle', 'water', 'sports', 'gym']
            },
            {
                'name': 'Digital Kitchen Scale',
                'category': 'Kitchen',
                'description': 'Precise digital scale for cooking and baking',
                'price': 19.99,
                'tags': ['scale', 'kitchen', 'cooking', 'measure']
            },
            {
                'name': 'Organic Bamboo Cutting Board Set',
                'category': 'Kitchen',
                'description': 'Set of 3 eco-friendly bamboo cutting boards',
                'price': 34.99,
                'tags': ['cutting board', 'kitchen', 'bamboo', 'eco']
            },
            {
                'name': 'Wireless Headphones',
                'category': 'Electronics',
                'description': 'Noise-cancelling wireless headphones with 30-hour battery',
                'price': 129.99,
                'tags': ['headphones', 'audio', 'wireless', 'music']
            },
            {
                'name': 'Dumbbells Set - 20 lbs',
                'category': 'Fitness',
                'description': 'Adjustable dumbbell set with carrying rack',
                'price': 89.99,
                'tags': ['dumbbells', 'weights', 'fitness', 'gym', 'home gym']
            },
            {
                'name': 'Organic Cotton T-Shirt',
                'category': 'Fashion',
                'description': 'Comfortable 100% organic cotton t-shirt',
                'price': 19.99,
                'tags': ['shirt', 'cotton', 'clothing', 'casual']
            },
            {
                'name': 'USB-C Fast Charger',
                'category': 'Electronics',
                'description': '65W USB-C fast charger compatible with most devices',
                'price': 39.99,
                'tags': ['charger', 'usb-c', 'fast charging', 'electronics']
            },
            {
                'name': 'Plant Pot with Saucer',
                'category': 'Home & Garden',
                'description': 'Modern ceramic plant pot with drainage hole',
                'price': 14.99,
                'tags': ['plant', 'pot', 'garden', 'home decor']
            },
        ]

        for prod_data in products_data:
            product, created = Product.objects.get_or_create(
                name=prod_data['name'],
                defaults={
                    'category': categories[prod_data['category']],
                    'description': prod_data['description'],
                    'current_price': prod_data['price'],
                    'stock': random.randint(5, 100),
                    'tags': prod_data['tags'],
                }
            )

            if created:
                self.stdout.write(f"✓ Created product: {prod_data['name']}")

                # Create price history (last 60 days)
                current_price = prod_data['price']
                for days_back in range(0, 60):
                    # Simulate price fluctuations
                    price_variation = random.uniform(-5, 5)
                    historical_price = current_price + price_variation

                    PriceHistory.objects.get_or_create(
                        product=product,
                        date=timezone.now().date() - timedelta(days=days_back),
                        defaults={'price': max(5, historical_price)}
                    )

                # Create price prediction
                from ml_engine.price_predictor import PricePredictor
                predictor = PricePredictor()
                predictor.save_predictions(product)
                self.stdout.write(f"  ✓ Created price prediction for {prod_data['name']}")

        self.stdout.write(self.style.SUCCESS('✅ Database seeded successfully!'))
