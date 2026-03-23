import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { WandSparkles, Loader2 } from 'lucide-react';
import { apiService } from '../api';
import { ProductCard } from '../components';
import styles from './CopilotPage.module.css';

const starterPrompts = [
  'Build a gaming PC under 80000',
  'Best laptop for coding under 70000',
  'Eco-friendly skincare under 1500'
];

const normalizeForCard = (item) => ({
  ...item,
  current_price: item.current_price ?? item.price,
});

const CopilotPage = ({ onViewDetails, onAddToCart }) => {
  const [query, setQuery] = useState(starterPrompts[0]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState(null);

  const runCopilot = async (value) => {
    const q = (value ?? query).trim();
    if (!q) {
      setError('Please enter a shopping query.');
      return;
    }

    setLoading(true);
    setError('');
    try {
      const data = await apiService.copilotRecommend(q);
      setResult(data);
    } catch (err) {
      setError(err?.message || 'Failed to get recommendations.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.page}>
      <motion.div
        className={styles.hero}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <div className={styles.titleRow}>
          <WandSparkles size={26} />
          <h1>Personal AI Shopping Copilot</h1>
        </div>
        <p>
          Ask in natural language. Copilot will extract intent, optimize by budget and relevance, and recommend products or a full setup.
        </p>
      </motion.div>

      <div className={styles.queryCard}>
        <label htmlFor="copilot-query">Your Query</label>
        <textarea
          id="copilot-query"
          rows={3}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Example: Build a gaming PC under 80000"
        />

        <div className={styles.promptRow}>
          {starterPrompts.map((p) => (
            <button
              key={p}
              type="button"
              className={styles.promptChip}
              onClick={() => {
                setQuery(p);
                runCopilot(p);
              }}
            >
              {p}
            </button>
          ))}
        </div>

        <button type="button" className={styles.submitBtn} onClick={() => runCopilot(query)} disabled={loading}>
          {loading ? <Loader2 className={styles.spin} size={18} /> : 'Get Recommendations'}
        </button>

        {error && <div className={styles.error}>{error}</div>}
      </div>

      {result && (
        <motion.div
          className={styles.results}
          initial={{ opacity: 0, y: 14 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <div className={styles.topGrid}>
            <div className={styles.panel}>
              <h3>Structured Query</h3>
              <pre>{JSON.stringify(result.structured_query || {}, null, 2)}</pre>
            </div>
            <div className={styles.panel}>
              <h3>Copilot Response</h3>
              <p>{result.ai_response}</p>
              <span className={styles.badge}>Type: {result.recommendation_type || 'single'}</span>
            </div>
          </div>

          <div className={styles.listHeader}>
            <h2>Recommended Products</h2>
            <span>{(result.products || []).length} items</span>
          </div>

          {(result.products || []).length === 0 ? (
            <div className={styles.empty}>No recommendations yet. Try a broader category or a higher budget.</div>
          ) : (
            <div className="product-grid">
              {result.products.map((item, idx) => (
                <div key={`${item.id || idx}-${item.component || 'item'}`}>
                  {item.component && <div className={styles.componentTag}>{item.component}</div>}
                  <ProductCard
                    product={normalizeForCard(item)}
                    onViewDetails={onViewDetails}
                    onAddCart={onAddToCart}
                  />
                </div>
              ))}
            </div>
          )}
        </motion.div>
      )}
    </div>
  );
};

export default CopilotPage;