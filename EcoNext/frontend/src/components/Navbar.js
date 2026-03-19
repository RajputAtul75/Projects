import React from 'react';
import { Link } from 'react-router-dom';
import styles from './Navbar.module.css';

const Navbar = () => {
    return (
        <nav className={styles.navbar}>
            <Link to="/" className={styles.brand}>EcoNext</Link>
            <div className={styles.links}>
                <Link to="/kids" className={styles.link}>Kids</Link>
                <Link to="/teens" className={styles.link}>Teens</Link>
                <Link to="/men" className={styles.link}>Men</Link>
                <Link to="/women" className={styles.link}>Women</Link>
                <Link to="/unisex" className={styles.link}>Unisex</Link>
            </div>
            <div className={styles.auth}>
                <Link to="/login" className={styles.link}>Login</Link>
                <Link to="/signup" className={`${styles.link} ${styles.signup}`}>Sign Up</Link>
            </div>
        </nav>
    );
};

export default Navbar;
