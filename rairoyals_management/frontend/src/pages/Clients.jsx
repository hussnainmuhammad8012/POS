import React, { useState, useEffect } from 'react'
import { Search, MoreVertical, Shield, ShieldOff, Calendar, Mail } from 'lucide-react'
import api from '../api'
import ClientModal from '../components/ClientModal'

const Clients = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);

  useEffect(() => {
    fetchClients();
  }, []);

  const fetchClients = async () => {
    try {
      const response = await api.get('/clients');
      setClients(response.data);
    } catch (err) {
      console.error('Error fetching clients:', err);
    } finally {
      setLoading(false);
    }
  };

  const toggleBlock = async (id, currentBlocked) => {
    try {
      await api.put(`/clients/${id}`, { isRemoteBlocked: !currentBlocked });
      fetchClients();
    } catch (err) {
      console.error('Error updating status:', err);
    }
  };

  return (
    <div className="clients-page">
      <div className="animate-fade-in">
        <header className="page-header">
          <div>
            <h1>Client Management</h1>
            <p>Manage licenses, trials, and access control.</p>
          </div>
          <button className="add-client-btn" onClick={() => setShowModal(true)}>+ New Client</button>
        </header>

        <div className="table-actions glass">
          <div className="search-bar">
            <Search size={18} />
            <input 
              type="text" 
              placeholder="Search by name, email or store..." 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div className="filters">
            <select>
              <option>All Status</option>
              <option>Active</option>
              <option>Trial</option>
              <option>Expired</option>
            </select>
          </div>
        </div>
      </div>

      {showModal && (
        <ClientModal 
          onClose={() => setShowModal(false)} 
          onSuccess={fetchClients} 
        />
      )}

      <div className="clients-table-container glass">
        <table className="clients-table">
          <thead>
            <tr>
              <th>Client / Store</th>
              <th>Status</th>
              <th>Trial Expiry</th>
              <th>License Key</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {clients.filter(c => 
              c.username?.toLowerCase().includes(searchTerm.toLowerCase()) || 
              c.storeName?.toLowerCase().includes(searchTerm.toLowerCase())
            ).map(client => (
              <tr key={client._id}>
                <td>
                  <div className="client-info">
                    <strong>{client.storeName || 'N/A'}</strong>
                    <span>{client.username} • {client.licenseKey}</span>
                  </div>
                </td>
                <td>
                  <span className={`status-badge ${client.status} ${client.isRemoteBlocked ? 'blocked' : ''}`}>
                    {client.isRemoteBlocked ? 'Blocked' : client.status?.toUpperCase()}
                  </span>
                </td>
                <td>
                  <div className="date-info">
                    <Calendar size={14} />
                    <span>{client.trialExpiryDate ? new Date(client.trialExpiryDate).toLocaleDateString() : 'N/A'}</span>
                  </div>
                </td>
                <td>
                  <code>{client.licenseKey}</code>
                </td>
                <td className="actions-cell">
                  <button className={`action-icon-btn ${client.isRemoteBlocked ? 'unblock' : 'block'}`} 
                          onClick={() => toggleBlock(client._id, client.isRemoteBlocked)}
                          title={client.isRemoteBlocked ? 'Unblock' : 'Block'}>
                    {client.isRemoteBlocked ? <Shield size={18} /> : <ShieldOff size={18} />}
                  </button>
                  <button className="action-icon-btn"><MoreVertical size={18} /></button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <style>{`
        .page-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 2.5rem;
        }
        .add-client-btn {
          padding: 0.8rem 1.5rem;
          background: var(--primary);
          color: white;
          font-weight: 600;
          border-radius: 12px;
        }
        .table-actions {
          display: flex;
          gap: 1.5rem;
          padding: 1.5rem;
          border-radius: 16px;
          margin-bottom: 1.5rem;
        }
        .search-bar {
          flex: 1;
          display: flex;
          align-items: center;
          gap: 0.8rem;
          background: var(--bg-dark);
          padding: 0 1rem;
          border-radius: 10px;
          border: 1px solid var(--border);
        }
        .search-bar input {
          width: 100%;
          padding: 0.7rem 0;
          background: transparent;
          border: none;
          color: white;
          outline: none;
        }
        .filters select {
          padding: 0.7rem 1rem;
          background: var(--bg-dark);
          color: white;
          border: 1px solid var(--border);
          border-radius: 10px;
          outline: none;
        }
        .clients-table-container {
          border-radius: 20px;
          overflow: hidden;
        }
        .clients-table {
          width: 100%;
          border-collapse: collapse;
          text-align: left;
        }
        .clients-table th {
          padding: 1.2rem 1.5rem;
          background: rgba(255, 255, 255, 0.03);
          color: var(--text-secondary);
          font-weight: 600;
          font-size: 0.85rem;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        .clients-table td {
          padding: 1.2rem 1.5rem;
          border-bottom: 1px solid rgba(255, 255, 255, 0.05);
        }
        .client-info {
          display: flex;
          flex-direction: column;
        }
        .client-info span {
          font-size: 0.8rem;
          color: var(--text-secondary);
        }
        .status-badge {
          padding: 0.25rem 0.75rem;
          border-radius: 20px;
          font-size: 0.75rem;
          font-weight: 600;
        }
        .status-badge.active { background: rgba(34, 197, 94, 0.1); color: var(--success); }
        .status-badge.trial { background: rgba(99, 102, 241, 0.1); color: var(--primary); }
        .status-badge.blocked { background: rgba(239, 68, 68, 0.1); color: var(--danger); }
        .date-info {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          color: var(--text-secondary);
          font-size: 0.9rem;
        }
        code {
          background: rgba(255, 255, 255, 0.05);
          padding: 0.2rem 0.4rem;
          border-radius: 4px;
          font-family: monospace;
          color: var(--primary);
        }
        .actions-cell {
          display: flex;
          gap: 0.5rem;
        }
        .action-icon-btn {
          width: 36px;
          height: 36px;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 8px;
          background: rgba(255, 255, 255, 0.05);
          color: var(--text-secondary);
          transition: 0.2s;
        }
        .action-icon-btn:hover {
          background: rgba(255, 255, 255, 0.1);
          color: var(--text-primary);
        }
        .action-icon-btn.unblock:hover { color: var(--success); }
        .action-icon-btn.block:hover { color: var(--danger); }
      `}</style>
    </div>
  )
}

export default Clients
