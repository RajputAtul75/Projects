import json
import os
import re
from dataclasses import dataclass
from decimal import Decimal
from typing import Any, Dict, List, Optional

import requests
from django.db.models import Q

from products.models import Product
from .prompts import QUERY_EXTRACTION_PROMPT, RECOMMENDATION_EXPLANATION_PROMPT


OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"


@dataclass
class StructuredQuery:
    budget: Optional[int]
    category: Optional[str]
    purpose: Optional[str]
    preferences: List[str]

    def as_dict(self) -> Dict[str, Any]:
        return {
            "budget": self.budget,
            "category": self.category,
            "purpose": self.purpose,
            "preferences": self.preferences,
        }


def _extract_first_json(text: str) -> Dict[str, Any]:
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise ValueError("No JSON object found")
    return json.loads(text[start : end + 1])


def _fallback_parse_query(query: str) -> StructuredQuery:
    budget = None
    budget_match = re.search(r"(?:under|below|<=?)\s*₹?\s*([\d,]+)|₹\s*([\d,]+)", query, flags=re.IGNORECASE)
    if budget_match:
        raw = budget_match.group(1) or budget_match.group(2)
        budget = int(raw.replace(",", ""))

    lowered = query.lower()
    category = None
    for candidate in ["pc", "laptop", "skincare", "phone", "monitor", "keyboard", "mouse"]:
        if candidate in lowered:
            category = "PC" if candidate == "pc" else candidate
            break

    purpose = None
    for candidate in ["gaming", "coding", "eco-friendly", "office", "study"]:
        if candidate in lowered:
            purpose = candidate
            break

    preferences = []
    if "eco" in lowered:
        preferences.append("eco-friendly")

    return StructuredQuery(budget=budget, category=category, purpose=purpose, preferences=preferences)


def extract_structured_query(query: str) -> StructuredQuery:
    api_key = os.getenv("OPENAI_API_KEY")
    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

    if not api_key:
        return _fallback_parse_query(query)

    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": QUERY_EXTRACTION_PROMPT},
            {"role": "user", "content": query},
        ],
        "temperature": 0,
    }

    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}

    try:
        response = requests.post(OPENAI_API_URL, headers=headers, json=payload, timeout=20)
        response.raise_for_status()
        content = response.json()["choices"][0]["message"]["content"]
        parsed = _extract_first_json(content)
        return StructuredQuery(
            budget=parsed.get("budget"),
            category=parsed.get("category"),
            purpose=parsed.get("purpose"),
            preferences=parsed.get("preferences") or [],
        )
    except Exception:
        return _fallback_parse_query(query)


def _relevance_score(product: Product, sq: StructuredQuery) -> float:
    score = 0.0
    hay = f"{product.name} {product.description}".lower()

    if sq.purpose and sq.purpose.lower() in hay:
        score += 2.0
    for pref in sq.preferences:
        if pref.lower() in hay:
            score += 1.0

    # Reuse existing fields as MVP proxies.
    score += float(product.popularity_score or 0.0) * 0.7
    score += float(product.sustainability_score or 0.0) * 0.3
    return score


def _product_to_dict(product: Product) -> Dict[str, Any]:
    return {
        "id": product.id,
        "name": product.name,
        "category": product.category.name if product.category_id else None,
        "price": float(product.current_price),
        "rating": round(float(product.popularity_score or 0.0), 2),
        "description": product.description,
        "image_url": product.image_url,
    }


def recommend_products(sq: StructuredQuery, top_n: int = 5) -> List[Dict[str, Any]]:
    products = Product.objects.select_related("category").all()

    if sq.category:
        cat = sq.category.strip()
        products = products.filter(
            Q(category__name__icontains=cat)
            | Q(name__icontains=cat)
            | Q(description__icontains=cat)
        )

    if sq.budget is not None:
        products = products.filter(current_price__lte=Decimal(sq.budget))

    ranked = sorted(products, key=lambda p: _relevance_score(p, sq), reverse=True)
    return [_product_to_dict(p) for p in ranked[:top_n]]


def build_pc_bundle(sq: StructuredQuery) -> List[Dict[str, Any]]:
    budget = sq.budget or 80000
    allocations = {
        "CPU": 0.22,
        "GPU": 0.35,
        "RAM": 0.10,
        "Motherboard": 0.12,
        "Storage": 0.10,
        "PSU": 0.06,
        "Case": 0.05,
    }

    bundle = []
    used = 0.0

    for part, ratio in allocations.items():
        part_budget = budget * ratio
        q = Product.objects.select_related("category").filter(
            Q(name__icontains=part) | Q(description__icontains=part)
        )
        if sq.budget is not None:
            q = q.filter(current_price__lte=Decimal(part_budget))

        part_products = sorted(q, key=lambda p: _relevance_score(p, sq), reverse=True)
        if not part_products:
            continue

        chosen = part_products[0]
        used += float(chosen.current_price)
        item = _product_to_dict(chosen)
        item["component"] = part
        bundle.append(item)

    if used > budget and bundle:
        # Simple budget guard for MVP.
        bundle = sorted(bundle, key=lambda i: i["price"])
        running = 0.0
        trimmed = []
        for item in bundle:
            if running + item["price"] <= budget:
                trimmed.append(item)
                running += item["price"]
        bundle = trimmed

    return bundle


def should_return_bundle(sq: StructuredQuery, raw_query: str) -> bool:
    query = raw_query.lower()
    return (sq.category or "").lower() == "pc" or "build" in query and "pc" in query


def generate_ai_response(raw_query: str, sq: StructuredQuery, products: List[Dict[str, Any]], recommendation_type: str) -> str:
    api_key = os.getenv("OPENAI_API_KEY")
    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

    context = {
        "query": raw_query,
        "structured_query": sq.as_dict(),
        "recommendation_type": recommendation_type,
        "products": products,
    }

    if not api_key:
        if not products:
            return "I could not find a strong match within your budget. Try increasing budget or broadening category."
        lines = [
            f"I found {len(products)} {recommendation_type} recommendation(s) for your request.",
            "Top picks are ranked by budget fit and relevance.",
        ]
        if sq.budget:
            lines.append(f"All options are within around Rs {sq.budget:,} when possible.")
        return " ".join(lines)

    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": RECOMMENDATION_EXPLANATION_PROMPT},
            {"role": "user", "content": json.dumps(context, ensure_ascii=True)},
        ],
        "temperature": 0.4,
    }
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}

    try:
        response = requests.post(OPENAI_API_URL, headers=headers, json=payload, timeout=20)
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"].strip()
    except Exception:
        if not products:
            return "I could not find a strong match within your budget. Try increasing budget or broadening category."
        return "Here are the best matches based on your budget and intent, sorted by relevance and product quality signals."
