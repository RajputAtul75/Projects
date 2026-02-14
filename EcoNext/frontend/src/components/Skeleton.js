import React from 'react';
import { motion } from 'framer-motion';
import styles from './Skeleton.module.css';

export const Skeleton = ({ 
  count = 1, 
  variant = 'card',
  width = '100%', 
  height = '100%' 
}) => {
  const shimmer = {
    initial: { backgroundPosition: '200% 0' },
    animate: {
      backgroundPosition: '-200% 0',
      transition: {
        duration: 2,
        repeat: Infinity,
        ease: 'linear',
      },
    },
  };

  if (variant === 'card') {
    return (
      <div className={styles.cardContainer}>
        {Array.from({ length: count }).map((_, idx) => (
          <motion.div
            key={idx}
            className={styles.skeletonCard}
            variants={shimmer}
            initial="initial"
            animate="animate"
          >
            <div className={styles.skeletonImage} />
            <div className={styles.skeletonContent}>
              <div className={styles.skeletonText} />
              <div className={styles.skeletonText} style={{ width: '80%' }} />
              <div className={styles.skeletonPrice} />
              <div className={styles.skeletonAction} />
            </div>
          </motion.div>
        ))}
      </div>
    );
  }

  return (
    <motion.div
      className={styles.skeleton}
      style={{ width, height }}
      variants={shimmer}
      initial="initial"
      animate="animate"
    />
  );
};

export default Skeleton;
