from decimal import Decimal
import random

from django.core.management.base import BaseCommand

from products.models import AgeGroup, Category, GenderCategory, Product


BASE_ITEMS = [
    {"name": "Graphic T-Shirt", "category": "Fashion", "price": (599, 1499), "tags": ["tshirt", "casual", "cotton"]},
    {"name": "Hooded Sweatshirt", "category": "Fashion", "price": (1299, 2899), "tags": ["hoodie", "winter", "casual"]},
    {"name": "Denim Jeans", "category": "Fashion", "price": (1499, 3499), "tags": ["denim", "jeans", "daily wear"]},
    {"name": "Running Sneakers", "category": "Fashion", "price": (1999, 4999), "tags": ["shoes", "running", "sports"]},
    {"name": "Classic Sneakers", "category": "Fashion", "price": (1699, 4299), "tags": ["shoes", "streetwear", "lifestyle"]},
    {"name": "Backpack", "category": "Fashion", "price": (899, 2499), "tags": ["bag", "travel", "daily carry"]},
    {"name": "Analog Watch", "category": "Fashion", "price": (1199, 3999), "tags": ["watch", "accessories", "style"]},
    {"name": "Smartwatch", "category": "Electronics", "price": (2499, 9999), "tags": ["smartwatch", "wearable", "fitness"]},
    {"name": "Wireless Earbuds", "category": "Electronics", "price": (1299, 6999), "tags": ["audio", "earbuds", "wireless"]},
    {"name": "Sports Shorts", "category": "Fashion", "price": (699, 1799), "tags": ["shorts", "sports", "gym"]},
    {"name": "Track Pants", "category": "Fashion", "price": (999, 2499), "tags": ["pants", "athleisure", "comfort"]},
    {"name": "Casual Shirt", "category": "Fashion", "price": (999, 2799), "tags": ["shirt", "casual", "weekend"]},
    {"name": "Formal Shirt", "category": "Fashion", "price": (1199, 3299), "tags": ["shirt", "formal", "office"]},
    {"name": "Kurta Set", "category": "Fashion", "price": (1399, 3999), "tags": ["ethnic", "traditional", "festival"]},
    {"name": "Party Dress", "category": "Fashion", "price": (1699, 4599), "tags": ["dress", "party", "fashion"]},
    {"name": "Sling Bag", "category": "Fashion", "price": (999, 2699), "tags": ["bag", "sling", "accessories"]},
    {"name": "Sunglasses", "category": "Fashion", "price": (799, 2999), "tags": ["sunglasses", "uv", "accessories"]},
    {"name": "Baseball Cap", "category": "Fashion", "price": (499, 1499), "tags": ["cap", "street", "summer"]},
    {"name": "Sports Bottle", "category": "Sports & Outdoors", "price": (399, 1199), "tags": ["bottle", "hydration", "sports"]},
    {"name": "Yoga Mat", "category": "Sports & Outdoors", "price": (899, 2499), "tags": ["yoga", "fitness", "exercise"]},
    {"name": "Study Table Lamp", "category": "Home & Kitchen", "price": (699, 2299), "tags": ["lamp", "study", "lighting"]},
    {"name": "Laptop Sleeve", "category": "Electronics", "price": (599, 1799), "tags": ["laptop", "sleeve", "protection"]},
    {"name": "Phone Case", "category": "Electronics", "price": (399, 1399), "tags": ["phone", "case", "accessories"]},
    {"name": "Portable Speaker", "category": "Electronics", "price": (1399, 5499), "tags": ["speaker", "music", "portable"]},
    {"name": "Classic Sandals", "category": "Fashion", "price": (799, 2499), "tags": ["sandals", "footwear", "daily wear"]},
]


SEGMENTS = {
    "Kids": {
        "age_group": "Kids",
        "gender": None,
        "keywords": "kids,toy,colorful,fashion",
    },
    "Teens": {
        "age_group": "Teens",
        "gender": None,
        "keywords": "teen,streetwear,fashion,lifestyle",
    },
    "Men": {
        "age_group": "Adults",
        "gender": "Men",
        "keywords": "men,fashion,menswear,style",
    },
    "Women": {
        "age_group": "Adults",
        "gender": "Women",
        "keywords": "women,fashion,womenswear,style",
    },
    "Unisex": {
        "age_group": "Adults",
        "gender": "Unisex",
        "keywords": "unisex,fashion,minimal,style",
    },
}


class Command(BaseCommand):
    help = "Seed 25 products each for Kids, Teens, Men, Women, and Unisex."

    def handle(self, *args, **options):
        random.seed(2026)

        self.stdout.write("Seeding segment products (25 per segment)...")

        for category_name in ["Fashion", "Electronics", "Sports & Outdoors", "Home & Kitchen"]:
            Category.objects.get_or_create(name=category_name, defaults={"description": f"{category_name} products"})

        for age_name in ["Kids", "Teens", "Adults"]:
            AgeGroup.objects.get_or_create(name=age_name)

        for gender_name in ["Men", "Women", "Unisex"]:
            GenderCategory.objects.get_or_create(name=gender_name)

        created_count = 0
        updated_count = 0

        for segment_name, segment_meta in SEGMENTS.items():
            age_group = AgeGroup.objects.get(name=segment_meta["age_group"])
            gender_name = segment_meta["gender"]
            gender = GenderCategory.objects.get(name=gender_name) if gender_name else None

            for i, item in enumerate(BASE_ITEMS, start=1):
                category = Category.objects.get(name=item["category"])

                min_price, max_price = item["price"]
                price = Decimal(str(random.randint(min_price, max_price)))
                stock = random.randint(20, 300)

                product_name = f"{segment_name} {item['name']}"
                image_keywords = f"{segment_meta['keywords']},{item['name'].replace(' ', ',').lower()}"
                image_url = f"https://loremflickr.com/1200/900/{image_keywords}?lock={i + (100 * list(SEGMENTS.keys()).index(segment_name))}"

                product, created = Product.objects.get_or_create(
                    name=product_name,
                    defaults={
                        "description": f"{segment_name} collection: {item['name']} with premium quality and modern styling.",
                        "category": category,
                        "current_price": price,
                        "image_url": image_url,
                        "stock": stock,
                        "tags": [segment_name.lower()] + item["tags"],
                    },
                )

                if created:
                    created_count += 1
                else:
                    product.category = category
                    product.current_price = price
                    product.image_url = image_url
                    product.stock = stock
                    product.tags = [segment_name.lower()] + item["tags"]
                    product.save(update_fields=["category", "current_price", "image_url", "stock", "tags", "updated_at"])
                    updated_count += 1

                product.age_groups.set([age_group])
                if gender:
                    product.gender_categories.set([gender])
                else:
                    product.gender_categories.clear()

            self.stdout.write(self.style.SUCCESS(f"{segment_name}: 25 products prepared"))

        self.stdout.write(self.style.SUCCESS(f"Done. Created: {created_count}, Updated: {updated_count}"))