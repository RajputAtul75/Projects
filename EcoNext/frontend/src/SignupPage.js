import React, { useState } from 'react';
import { apiService } from './api';
import { Mail, Lock, User, Eye, EyeOff, AlertCircle, CheckCircle, Leaf, ArrowRight } from 'lucide-react';
import { motion } from 'framer-motion';

function SignupPage({ onSignupSuccess, onSwitchPage }) {
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    first_name: '',
    last_name: '',
    password: '',
    password_confirm: ''
  });
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState({});
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [step, setStep] = useState(1);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: ''
      }));
    }
  };

  const validateForm = () => {
    const newErrors = {};

    if (formData.username.length < 3) {
      newErrors.username = 'Username must be at least 3 characters';
    }
    if (formData.email && !formData.email.includes('@')) {
      newErrors.email = 'Enter a valid email address';
    }
    if (formData.password.length < 6) {
      newErrors.password = 'Password must be at least 6 characters';
    }
    if (formData.password !== formData.password_confirm) {
      newErrors.password_confirm = 'Passwords do not match';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleNext = () => {
    if (step === 1) {
      if (formData.first_name.trim() || formData.last_name.trim() || formData.email.trim()) {
        setStep(2);
      } else {
        setErrors({ general: 'Please fill in at least one field' });
      }
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setLoading(true);
    setErrors({});

    try {
      const response = await apiService.signup(formData);
      if (response.status === 'success') {
        localStorage.setItem('authToken', response.tokens.access);
        localStorage.setItem('refreshToken', response.tokens.refresh);
        localStorage.setItem('user', JSON.stringify(response.user));
        onSignupSuccess(response);
      } else {
        setErrors(response.errors || { general: 'Signup failed' });
      }
    } catch (err) {
      setErrors({ general: 'An error occurred during signup' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page-container">
      <motion.div 
        className="auth-background"
        animate={{ backgroundPosition: ['0% 0%', '100% 100%'] }}
        transition={{ duration: 20, repeat: Infinity, repeatType: 'reverse' }}
      />
      
      <div className="auth-content">
        {/* Left Side - Branding */}
        <motion.div 
          className="auth-branding"
          initial={{ opacity: 0, x: -50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.6 }}
        >
          <div className="brand-icon">
            <Leaf size={48} />
          </div>
          <h2>Join EcoNext</h2>
          <p>Start your sustainable shopping journey and discover eco-friendly products from premium Indian marketplaces</p>
          
          <div className="features-list">
            <div className="feature-item">
              <CheckCircle size={20} />
              <span>Access 117+ Products</span>
            </div>
            <div className="feature-item">
              <CheckCircle size={20} />
              <span>Smart Price Tracking</span>
            </div>
            <div className="feature-item">
              <CheckCircle size={20} />
              <span>Personalized Recommendations</span>
            </div>
            <div className="feature-item">
              <CheckCircle size={20} />
              <span>Secure Checkout</span>
            </div>
          </div>
        </motion.div>

        {/* Right Side - Signup Form */}
        <motion.div 
          className="auth-form-container"
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
        >
          <div className="form-header">
            <h1>Create Account</h1>
            <p>{step === 1 ? 'Tell us about yourself' : 'Create your password'}</p>
          </div>

          {/* Progress Steps */}
          <div className="progress-steps">
            <div className={`step ${step >= 1 ? 'active' : ''}`}>
              <span>1</span>
            </div>
            <div className={`step-line ${step >= 2 ? 'active' : ''}`}></div>
            <div className={`step ${step >= 2 ? 'active' : ''}`}>
              <span>2</span>
            </div>
          </div>

          {/* Error Alert */}
          {errors.general && (
            <motion.div 
              className="alert-box alert-error"
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
            >
              <AlertCircle size={18} />
              <span>{errors.general}</span>
            </motion.div>
          )}

          <form onSubmit={handleSubmit}>
            {/* Step 1: Personal Information */}
            {step === 1 && (
              <motion.div
                key="step1"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
              >
                {/* Name Fields */}
                <div className="form-group-row">
                  <div className="form-group">
                    <label htmlFor="first_name">First Name</label>
                    <div className="input-wrapper">
                      <User size={18} className="input-icon" />
                      <input
                        id="first_name"
                        type="text"
                        name="first_name"
                        placeholder="John"
                        value={formData.first_name}
                        onChange={handleChange}
                        className="form-input"
                      />
                    </div>
                  </div>
                  <div className="form-group">
                    <label htmlFor="last_name">Last Name</label>
                    <div className="input-wrapper">
                      <User size={18} className="input-icon" />
                      <input
                        id="last_name"
                        type="text"
                        name="last_name"
                        placeholder="Doe"
                        value={formData.last_name}
                        onChange={handleChange}
                        className="form-input"
                      />
                    </div>
                  </div>
                </div>

                {/* Email Field */}
                <div className="form-group">
                  <label htmlFor="email">Email Address</label>
                  <div className="input-wrapper">
                    <Mail size={18} className="input-icon" />
                    <input
                      id="email"
                      type="email"
                      name="email"
                      placeholder="your@email.com"
                      value={formData.email}
                      onChange={handleChange}
                      required
                      autoComplete="email"
                      className="form-input"
                    />
                  </div>
                  {errors.email && <span className="error-text"><AlertCircle size={14} /> {errors.email}</span>}
                </div>

                {/* Username Field */}
                <div className="form-group">
                  <label htmlFor="username">Username</label>
                  <div className="input-wrapper">
                    <User size={18} className="input-icon" />
                    <input
                      id="username"
                      type="text"
                      name="username"
                      placeholder="Choose a username"
                      value={formData.username}
                      onChange={handleChange}
                      required
                      autoComplete="username"
                      className="form-input"
                    />
                  </div>
                  {errors.username && <span className="error-text"><AlertCircle size={14} /> {errors.username}</span>}
                </div>

                {/* Next Button */}
                <motion.button
                  type="button"
                  className="btn-submit"
                  onClick={handleNext}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                >
                  Continue
                  <ArrowRight size={18} />
                </motion.button>
              </motion.div>
            )}

            {/* Step 2: Password Setup */}
            {step === 2 && (
              <motion.div
                key="step2"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
              >
                {/* Password Field */}
                <div className="form-group">
                  <label htmlFor="password">Password</label>
                  <div className="input-wrapper">
                    <Lock size={18} className="input-icon" />
                    <input
                      id="password"
                      type={showPassword ? 'text' : 'password'}
                      name="password"
                      placeholder="At least 6 characters"
                      value={formData.password}
                      onChange={handleChange}
                      required
                      autoComplete="new-password"
                      className="form-input"
                    />
                    <button
                      type="button"
                      className="toggle-password-btn"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                  {errors.password && <span className="error-text"><AlertCircle size={14} /> {errors.password}</span>}
                  <div className="password-strength">
                    <div className={`strength-indicator ${formData.password.length >= 8 ? 'strong' : formData.password.length >= 6 ? 'medium' : 'weak'}`}></div>
                    <span className="strength-text">
                      {formData.password.length >= 8 ? 'Strong' : formData.password.length >= 6 ? 'Medium' : 'Weak'}
                    </span>
                  </div>
                </div>

                {/* Confirm Password Field */}
                <div className="form-group">
                  <label htmlFor="password_confirm">Confirm Password</label>
                  <div className="input-wrapper">
                    <Lock size={18} className="input-icon" />
                    <input
                      id="password_confirm"
                      type={showConfirmPassword ? 'text' : 'password'}
                      name="password_confirm"
                      placeholder="Confirm your password"
                      value={formData.password_confirm}
                      onChange={handleChange}
                      required
                      autoComplete="new-password"
                      className="form-input"
                    />
                    <button
                      type="button"
                      className="toggle-password-btn"
                      onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    >
                      {showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                  {errors.password_confirm && <span className="error-text"><AlertCircle size={14} /> {errors.password_confirm}</span>}
                  {formData.password && formData.password_confirm && formData.password === formData.password_confirm && (
                    <span className="success-text"><CheckCircle size={14} /> Passwords match</span>
                  )}
                </div>

                {/* Submit Button */}
                <motion.button
                  type="submit"
                  className="btn-submit"
                  disabled={loading}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                >
                  {loading ? (
                    <>
                      <span className="loader"></span>
                      Creating Account...
                    </>
                  ) : (
                    <>
                      Create Account
                      <ArrowRight size={18} />
                    </>
                  )}
                </motion.button>

                {/* Back Button */}
                <button
                  type="button"
                  className="btn-back"
                  onClick={() => setStep(1)}
                  disabled={loading}
                >
                  Back
                </button>
              </motion.div>
            )}
          </form>

          {/* Divider */}
          <div className="divider">
            <span>Already have an account?</span>
          </div>

          {/* Sign In Link */}
          <motion.button
            type="button"
            className="btn-secondary"
            onClick={() => onSwitchPage('login')}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            Sign In
          </motion.button>

          {/* Footer */}
          <p className="form-footer">
            By creating an account, you agree to our <a href="#">Terms of Service</a> and <a href="#">Privacy Policy</a>
          </p>
        </motion.div>
      </div>
    </div>
  );
}

export default SignupPage;
