import React, { useState } from 'react';
import { X, Shield, Store, User, Key, Calendar } from 'lucide-react';
import api from '../api';

const ClientModal = ({ onClose, onSuccess }) => {
  const [formData, setFormData] = useState({
    username: '',
    storeName: '',
    licenseKey: '',
    status: 'trial',
    trialExpiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const generateKey = () => {
    const key = 'RR-' + Math.random().toString(36).substring(2, 6).toUpperCase() + '-' + 
                Math.random().toString(36).substring(2, 6).toUpperCase();
    setFormData({ ...formData, licenseKey: key });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      await api.post('/clients', formData);
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to create client');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content glass animate-scale-in">
        <div className="modal-header">
          <h3>Register New Client</h3>
          <button onClick={onClose}><X size={20} /></button>
        </div>

        <form onSubmit={handleSubmit}>
          {error && <div className="error-badge">{error}</div>}

          <div className="input-field">
            <label><User size={16} /> Admin Username</label>
            <input 
              type="text" 
              placeholder="e.g. hussnain_muhammad" 
              value={formData.username}
              onChange={(e) => setFormData({...formData, username: e.target.value})}
              required
            />
          </div>

          <div className="input-field">
            <label><Store size={16} /> Store Name</label>
            <input 
              type="text" 
              placeholder="e.g. Al-Madina Supermarket" 
              value={formData.storeName}
              onChange={(e) => setFormData({...formData, storeName: e.target.value})}
              required
            />
          </div>

          <div className="input-field">
            <label><Key size={16} /> License Key</label>
            <div className="key-input">
              <input 
                type="text" 
                placeholder="Click generate ->" 
                value={formData.licenseKey}
                onChange={(e) => setFormData({...formData, licenseKey: e.target.value})}
                required
              />
              <button type="button" onClick={generateKey}>Generate</button>
            </div>
          </div>

          <div className="row">
            <div className="input-field">
              <label><Shield size={16} /> Status</label>
              <select 
                value={formData.status}
                onChange={(e) => setFormData({...formData, status: e.target.value})}
              >
                <option value="trial">Trial</option>
                <option value="active">Active (Lifetime)</option>
              </select>
            </div>

            <div className="input-field">
              <label><Calendar size={16} /> Trial Expiry</label>
              <input 
                type="date" 
                value={formData.trialExpiryDate}
                disabled={formData.status === 'active'}
                onChange={(e) => setFormData({...formData, trialExpiryDate: e.target.value})}
              />
            </div>
          </div>

          <button type="submit" className="submit-btn" disabled={loading}>
            {loading ? 'Processing...' : 'Register client'}
          </button>
        </form>
      </div>

      <style>{`
        .modal-overlay {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.8);
          backdrop-filter: blur(8px);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 100000; /* Over everything */
        }
        .modal-content {
          width: 550px;
          max-height: 90vh;
          overflow-y: auto;
          padding: 3rem;
          background: var(--bg-card);
          border-radius: 32px;
          box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
          position: relative;
        }
        .modal-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 2.5rem;
        }
        .modal-header h3 { font-size: 1.6rem; letter-spacing: -0.5px; }
        .modal-header button { 
          background: rgba(255, 255, 255, 0.05); 
          color: var(--text-secondary); 
          padding: 0.5rem;
          border-radius: 50%;
        }
        .modal-header button:hover {
          background: rgba(255, 255, 255, 0.1);
          color: white;
        }
        
        form { display: flex; flex-direction: column; gap: 1.5rem; }
        .input-field { display: flex; flex-direction: column; gap: 0.7rem; }
        .input-field label { 
          display: flex; 
          align-items: center; 
          gap: 0.5rem; 
          font-size: 0.9rem; 
          font-weight: 500;
          color: var(--text-secondary); 
        }
        input, select {
          padding: 1rem 1.2rem;
          background: var(--bg-dark);
          border: 1px solid var(--border);
          border-radius: 16px;
          color: white;
          font-size: 1rem;
          outline: none;
          transition: all 0.2s;
        }
        input:focus, select:focus { border-color: var(--primary); box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1); }
        .key-input { display: flex; gap: 0.8rem; }
        .key-input input { flex: 1; font-family: 'JetBrains Mono', monospace; font-size: 0.9rem; letter-spacing: 1px; }
        .key-input button {
          padding: 0 1.5rem;
          background: var(--primary);
          color: white;
          border-radius: 12px;
          font-size: 0.85rem;
          font-weight: 600;
          transition: 0.2s;
        }
        .key-input button:hover { transform: translateY(-1px); filter: brightness(1.1); }
        .row { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }
        .submit-btn {
          margin-top: 1.5rem;
          padding: 1.2rem;
          background: var(--primary);
          color: white;
          font-size: 1.1rem;
          font-weight: 700;
          border-radius: 16px;
          box-shadow: 0 10px 20px -5px rgba(99, 102, 241, 0.4);
        }
        .submit-btn:hover { transform: translateY(-2px); box-shadow: 0 15px 30px -10px rgba(99, 102, 241, 0.5); }
        .error-badge {
          padding: 1rem;
          background: rgba(239, 68, 68, 0.1);
          border: 1px solid rgba(239, 68, 68, 0.2);
          color: var(--danger);
          border-radius: 12px;
          font-size: 0.9rem;
          text-align: center;
        }
        /* Custom scrollbar for modal content if it overflows */
        .modal-content::-webkit-scrollbar { width: 6px; }
        .modal-content::-webkit-scrollbar-track { background: transparent; }
        .modal-content::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 10px; }
      `}</style>
    </div>
  );
};

export default ClientModal;
