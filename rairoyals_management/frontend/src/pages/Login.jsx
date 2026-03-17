import React, { useState } from 'react'
import { ShieldCheck, Lock, User } from 'lucide-react'
import api from '../api'

const Login = ({ onLogin }) => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      const response = await api.post('/admin/login', { username, password });
      localStorage.setItem('token', response.data.token);
      localStorage.setItem('admin', JSON.stringify(response.data.admin));
      onLogin();
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to login. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      <div className="login-card glass glow animate-fade-in">
        <div className="logo-section">
          <div className="logo-icon">
            <ShieldCheck size={40} color="var(--primary)" />
          </div>
          <h1>RaiRoyalsCode</h1>
          <p>Management Hub</p>
        </div>

        <form onSubmit={handleSubmit}>
          {error && <div className="error-message">{error}</div>}
          
          <div className="input-group">
            <User size={18} />
            <input 
              type="text" 
              placeholder="Username" 
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required 
            />
          </div>

          <div className="input-group">
            <Lock size={18} />
            <input 
              type="password" 
              placeholder="Password" 
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required 
            />
          </div>

          <button type="submit" disabled={loading}>
            {loading ? 'Authenticating...' : 'Access Dashboard'}
          </button>
        </form>
      </div>

      <style>{`
        .login-page {
          height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          background: radial-gradient(circle at top right, #1e1b4b, var(--bg-dark));
        }
        .login-card {
          width: 400px;
          padding: 3rem;
          border-radius: 24px;
          text-align: center;
        }
        .logo-section {
          margin-bottom: 2.5rem;
        }
        .logo-icon {
          display: inline-flex;
          padding: 1rem;
          background: rgba(99, 102, 241, 0.1);
          border-radius: 50%;
          margin-bottom: 1rem;
        }
        h1 {
          font-size: 1.8rem;
          color: var(--text-primary);
          letter-spacing: -0.5px;
        }
        p {
          color: var(--text-secondary);
          font-size: 0.9rem;
          margin-top: 0.2rem;
        }
        form {
          display: flex;
          flex-direction: column;
          gap: 1.2rem;
        }
        .error-message {
          padding: 0.8rem;
          background: rgba(239, 68, 68, 0.1);
          color: var(--danger);
          border-radius: 8px;
          font-size: 0.85rem;
        }
        .input-group {
          position: relative;
          display: flex;
          align-items: center;
          background: var(--bg-dark);
          border: 1px solid var(--border);
          border-radius: 12px;
          padding: 0 1rem;
          transition: border-color 0.2s;
        }
        .input-group:focus-within {
          border-color: var(--primary);
        }
        .input-group svg {
          color: var(--text-secondary);
        }
        input {
          width: 100%;
          padding: 1rem;
          background: transparent;
          border: none;
          color: var(--text-primary);
          font-size: 1rem;
          outline: none;
        }
        button {
          padding: 1rem;
          background: var(--primary);
          color: white;
          font-weight: 600;
          border-radius: 12px;
          margin-top: 0.5rem;
          box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
        }
        button:hover {
          background: var(--primary-hover);
          transform: translateY(-1px);
        }
      `}</style>
    </div>
  )
}

export default Login
