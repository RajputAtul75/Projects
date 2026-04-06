"""Visual search engine with CLIP + FAISS and histogram fallback."""

import os
from io import BytesIO

import cv2
import numpy as np
import requests
from PIL import Image

from django.conf import settings
from products.models import Product

try:
    import faiss
except Exception:  # pragma: no cover
    faiss = None

try:
    import torch
    from transformers import CLIPModel, CLIPProcessor
except Exception:  # pragma: no cover
    torch = None
    CLIPModel = None
    CLIPProcessor = None


class VisualSearchEngine:
    """CLIP-based product retrieval engine with FAISS ANN index."""

    def __init__(self):
        self.model_name = os.getenv("VISUAL_MODEL_NAME", "openai/clip-vit-base-patch32")
        self.index_dir = os.path.join(settings.BASE_DIR, "ml_engine")
        self.clip_embeddings_path = os.path.join(self.index_dir, "clip_embeddings.npy")
        self.clip_ids_path = os.path.join(self.index_dir, "clip_product_ids.npy")
        self.faiss_index_path = os.path.join(self.index_dir, "clip_faiss.index")
        self.hist_vectors_path = os.path.join(self.index_dir, "feature_vectors.npy")

        self.clip_enabled = bool(torch and CLIPModel and CLIPProcessor)
        self.faiss_enabled = bool(faiss is not None)
        self.device = "cpu"
        self.clip_ready = False

        self.model = None
        self.processor = None
        self.faiss_index = None
        self.clip_embeddings = None
        self.product_ids = np.array([], dtype=np.int64)

        self.feature_vectors = {}

        if not self.clip_enabled:
            print("CLIP dependencies are not available. Falling back to histogram search.")

        self.feature_vectors = self._load_or_create_histogram_vectors()

    def _ensure_clip_ready(self):
        """Lazily initializes CLIP model and index on first use."""
        if not self.clip_enabled:
            return False
        if self.clip_ready:
            return True
        try:
            self._init_clip()
            self._load_or_build_clip_index()
            self.clip_ready = True
            return True
        except Exception as exc:
            print(f"CLIP initialization failed, using histogram fallback: {exc}")
            self.clip_enabled = False
            return False

    def _init_clip(self):
        """Initializes CLIP model and processor."""
        self.model = CLIPModel.from_pretrained(self.model_name)
        self.processor = CLIPProcessor.from_pretrained(self.model_name)
        self.model.to(self.device)
        self.model.eval()

    def _open_image(self, image_path_or_stream):
        """Loads an image from a file path or stream as RGB PIL image."""
        if isinstance(image_path_or_stream, str):
            return Image.open(image_path_or_stream).convert("RGB")
        if hasattr(image_path_or_stream, "seek"):
            image_path_or_stream.seek(0)
        return Image.open(image_path_or_stream).convert("RGB")

    def _download_image(self, image_url):
        """Downloads a URL image into memory as PIL image."""
        response = requests.get(image_url, timeout=5)
        response.raise_for_status()
        return Image.open(BytesIO(response.content)).convert("RGB")

    def _encode_clip_image(self, image):
        """Encodes a PIL image into an L2-normalized CLIP embedding."""
        inputs = self.processor(images=image, return_tensors="pt")
        inputs = {k: v.to(self.device) for k, v in inputs.items()}
        with torch.no_grad():
            feats = self.model.get_image_features(**inputs)

        if hasattr(feats, "cpu"):
            emb_tensor = feats
        elif hasattr(feats, "image_embeds"):
            emb_tensor = feats.image_embeds
        elif hasattr(feats, "pooler_output"):
            emb_tensor = feats.pooler_output
        else:
            raise ValueError("Unexpected CLIP output structure during image encoding")

        embedding = emb_tensor.cpu().numpy().astype(np.float32)
        norm = np.linalg.norm(embedding, axis=1, keepdims=True)
        embedding = embedding / np.clip(norm, 1e-12, None)
        return embedding[0]

    def _build_clip_index(self):
        """Builds CLIP embeddings and FAISS index from product image URLs."""
        product_ids = []
        embeddings = []
        products = Product.objects.exclude(image_url__isnull=True).exclude(image_url="")

        for product in products:
            try:
                image = self._download_image(product.image_url)
                emb = self._encode_clip_image(image)
                product_ids.append(product.id)
                embeddings.append(emb)
            except Exception as exc:
                print(f"Skipping product {product.id} for CLIP index: {exc}")

        if not embeddings:
            self.product_ids = np.array([], dtype=np.int64)
            self.clip_embeddings = np.empty((0, 512), dtype=np.float32)
            self.faiss_index = None
            return

        self.product_ids = np.asarray(product_ids, dtype=np.int64)
        self.clip_embeddings = np.asarray(embeddings, dtype=np.float32)

        np.save(self.clip_ids_path, self.product_ids)
        np.save(self.clip_embeddings_path, self.clip_embeddings)

        if self.faiss_enabled:
            dim = self.clip_embeddings.shape[1]
            index = faiss.IndexFlatIP(dim)
            index.add(self.clip_embeddings)
            faiss.write_index(index, self.faiss_index_path)
            self.faiss_index = index
        else:
            self.faiss_index = None

    def _load_or_build_clip_index(self):
        """Loads CLIP artifacts if available, otherwise builds them."""
        artifacts_exist = (
            os.path.exists(self.clip_embeddings_path)
            and os.path.exists(self.clip_ids_path)
            and (not self.faiss_enabled or os.path.exists(self.faiss_index_path))
        )

        if artifacts_exist:
            try:
                self.clip_embeddings = np.load(self.clip_embeddings_path)
                self.product_ids = np.load(self.clip_ids_path)
                if self.faiss_enabled:
                    self.faiss_index = faiss.read_index(self.faiss_index_path)
                return
            except Exception:
                pass

        self._build_clip_index()

    def _extract_histogram_features(self, image_path_or_stream):
        """Extracts fallback histogram features from an image."""
        try:
            image = self._open_image(image_path_or_stream)
            image = image.resize((128, 128))
            cv_image = np.array(image)
            hist = cv2.calcHist([cv_image], [0, 1, 2], None, [8, 8, 8], [0, 256, 0, 256, 0, 256])
            cv2.normalize(hist, hist)
            return hist.flatten().astype(np.float32)
        except Exception as exc:
            print(f"Error extracting histogram features: {exc}")
            return None

    def _extract_histogram_from_url(self, image_url):
        """Downloads an image and extracts histogram features."""
        if not image_url:
            return None
        try:
            image = self._download_image(image_url)
            return self._extract_histogram_features(BytesIO(image.tobytes()))
        except Exception:
            try:
                response = requests.get(image_url, timeout=8)
                response.raise_for_status()
                return self._extract_histogram_features(BytesIO(response.content))
            except Exception as exc:
                print(f"Error extracting histogram from URL {image_url}: {exc}")
                return None

    def _load_or_create_histogram_vectors(self):
        """Loads or creates histogram feature vectors for fallback search."""
        if os.path.exists(self.hist_vectors_path):
            try:
                return np.load(self.hist_vectors_path, allow_pickle=True).item()
            except Exception:
                pass

        vectors = {}
        products = Product.objects.exclude(image_url__isnull=True).exclude(image_url="")
        for product in products:
            try:
                response = requests.get(product.image_url, timeout=8)
                response.raise_for_status()
                vector = self._extract_histogram_features(BytesIO(response.content))
                if vector is not None:
                    vectors[product.id] = vector
            except Exception as exc:
                print(f"Skipping product {product.id} for histogram vectors: {exc}")

        np.save(self.hist_vectors_path, vectors)
        return vectors

    def refresh_feature_vectors(self):
        """Regenerates CLIP and histogram artifacts."""
        for path in [self.clip_embeddings_path, self.clip_ids_path, self.faiss_index_path, self.hist_vectors_path]:
            if os.path.exists(path):
                try:
                    os.remove(path)
                except Exception:
                    pass

        if self.clip_enabled:
            self._build_clip_index()
        self.feature_vectors = self._load_or_create_histogram_vectors()

    def _clip_search(self, query_image_stream, top_k):
        """Runs CLIP similarity search using FAISS or numpy fallback."""
        if not self._ensure_clip_ready():
            return []

        if self.clip_embeddings is None or self.product_ids.size == 0:
            self._load_or_build_clip_index()
            if self.product_ids.size == 0:
                return []

        query_image = self._open_image(query_image_stream)
        query_emb = self._encode_clip_image(query_image).astype(np.float32).reshape(1, -1)

        max_k = int(min(max(top_k, 1), len(self.product_ids)))
        if max_k <= 0:
            return []

        if self.faiss_enabled and self.faiss_index is not None:
            scores, indices = self.faiss_index.search(query_emb, max_k)
            scores = scores[0]
            indices = indices[0]
        else:
            scores = np.dot(self.clip_embeddings, query_emb[0])
            sorted_idx = np.argsort(-scores)[:max_k]
            indices = sorted_idx
            scores = scores[sorted_idx]

        similar_products = []
        for idx, raw_score in zip(indices, scores):
            if idx < 0 or idx >= len(self.product_ids):
                continue
            product_id = int(self.product_ids[idx])
            try:
                product = Product.objects.get(id=product_id)
                similarity = float(np.clip((float(raw_score) + 1.0) / 2.0, 0.0, 1.0))
                similar_products.append({"product": product, "similarity_score": similarity})
            except Product.DoesNotExist:
                continue
        return similar_products

    def _histogram_search(self, query_image_stream, top_k):
        """Runs fallback histogram search."""
        query_features = self._extract_histogram_features(query_image_stream)
        if query_features is None:
            return []

        if not self.feature_vectors:
            self.feature_vectors = self._load_or_create_histogram_vectors()
            if not self.feature_vectors:
                return []

        results = []
        for product_id, feature_vector in self.feature_vectors.items():
            candidate_vector = np.asarray(feature_vector, dtype=np.float32).flatten()
            distance = cv2.compareHist(query_features, candidate_vector, cv2.HISTCMP_CHISQR)
            results.append((product_id, distance))

        results.sort(key=lambda item: item[1])
        similar_products = []
        for product_id, distance in results[:top_k]:
            try:
                product = Product.objects.get(id=product_id)
                similarity = float(max(0.0, 1.0 - (distance / 100.0)))
                similar_products.append({"product": product, "similarity_score": similarity})
            except Product.DoesNotExist:
                continue
        return similar_products

    def search(self, query_image_stream, top_k=10):
        """Finds top-k visually similar products."""
        clip_results = self._clip_search(query_image_stream, top_k)
        if clip_results:
            return clip_results
        return self._histogram_search(query_image_stream, top_k)


visual_search_engine = VisualSearchEngine()
