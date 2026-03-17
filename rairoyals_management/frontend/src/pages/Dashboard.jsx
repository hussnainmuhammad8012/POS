import React, { useState, useEffect } from 'react'
import { Users, CreditCard, ShieldAlert, MessageSquare } from 'lucide-react'
import api from '../api'

const Dashboard = () => {
  const [stats, setStats] = useState({
    totalClients: 0,
    activeTrials: 0,
    blockedClients: 0,
    newFeedback: 0
  });
  const [loading, setLoading] = useState(true);

  const [recentClients, setRecentClients] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsRes, clientsRes] = await Promise.all([
          api.get('/admin/stats'),
          api.get('/clients')
        ]);
        setStats(statsRes.data);
        // Sort clients by creation date descending and take top 5
        const sorted = clientsRes.data.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)).slice(0, 5);
        setRecentClients(sorted);
      } catch (err) {
        console.error('Error fetching dashboard data:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Initializing Management Hub...</p>
        <style>{`
          .loading-container { height: 80vh; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 1rem; color: var(--text-secondary); }
          .spinner { width: 40px; height: 40px; border: 3px solid rgba(99, 102, 241, 0.1); border-top-color: var(--primary); border-radius: 50%; animation: spin 1s linear infinite; }
          @keyframes spin { to { transform: rotate(360deg); } }
        `}</style>
      </div>
    );
  }

  return (
    <div className="dashboard-page animate-fade-in">
      <header>
        <h1>System Overview</h1>
        <p>Monitor your clients and feedback in real-time.</p>
      </header>

      <div className="stats-grid">
        <StatCard 
          icon={<Users color="#6366f1" />} 
          label="Total Clients" 
          value={stats.totalClients} 
          trend="Overall registrations" 
        />
        <StatCard 
          icon={<CreditCard color="#22c55e" />} 
          label="Active Trials" 
          value={stats.activeTrials} 
          trend="Current evaluations" 
        />
        <StatCard 
          icon={<ShieldAlert color="#ef4444" />} 
          label="Blocked Accounts" 
          value={stats.blockedClients} 
          trend="Access restricted" 
        />
        <StatCard 
          icon={<MessageSquare color="#f59e0b" />} 
          label="Pending Feedback" 
          value={stats.newFeedback} 
          trend="Waiting processing" 
        />
      </div>

      <div className="recent-activity glass">
        <h3>Recent Registrations</h3>
        <div className="activity-list">
          {recentClients.length > 0 ? recentClients.map(client => (
            <ActivityItem 
              key={client._id}
              label="New client registered" 
              time={new Date(client.createdAt).toLocaleDateString()} 
              client={`${client.storeName} (${client.username})`} 
            />
          )) : (
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>No recent activity found.</p>
          )}
        </div>
      </div>

      <style>{`
        .dashboard-page h1 {
          font-size: 2rem;
          margin-bottom: 0.5rem;
        }
        .dashboard-page p {
          color: var(--text-secondary);
          margin-bottom: 2.5rem;
        }
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
          gap: 1.5rem;
          margin-bottom: 2.5rem;
        }
        .recent-activity {
          padding: 2rem;
          border-radius: 24px;
        }
        .recent-activity h3 {
          margin-bottom: 1.5rem;
          font-size: 1.2rem;
        }
        .activity-list {
          display: flex;
          flex-direction: column;
          gap: 1.2rem;
        }
      `}</style>
    </div>
  )
}

const StatCard = ({ icon, label, value, trend }) => (
  <div className="stat-card glass">
    <div className="stat-header">
      <div className="stat-icon">{icon}</div>
      <span className="trend">{trend}</span>
    </div>
    <div className="stat-body">
      <h2>{value}</h2>
      <span>{label}</span>
    </div>
    <style>{`
      .stat-card {
        padding: 1.5rem;
        border-radius: 20px;
        transition: transform 0.2s;
      }
      .stat-card:hover {
        transform: translateY(-5px);
      }
      .stat-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 1.5rem;
      }
      .stat-icon {
        padding: 0.8rem;
        background: rgba(255, 255, 255, 0.05);
        border-radius: 12px;
      }
      .trend {
        font-size: 0.75rem;
        color: var(--success);
        font-weight: 500;
        background: rgba(34, 197, 94, 0.1);
        padding: 0.2rem 0.6rem;
        border-radius: 20px;
      }
      .stat-body h2 {
        font-size: 2rem;
        margin-bottom: 0.2rem;
      }
      .stat-body span {
        font-size: 0.9rem;
        color: var(--text-secondary);
      }
    `}</style>
  </div>
)

const ActivityItem = ({ label, time, client }) => (
  <div className="activity-item">
    <div className="dot"></div>
    <div className="content">
      <strong>{label}</strong>
      <span>{client}</span>
    </div>
    <span className="time">{time}</span>
    <style>{`
      .activity-item {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding-bottom: 1.2rem;
        border-bottom: 1px solid rgba(255, 255, 255, 0.05);
      }
      .activity-item:last-child {
        border-bottom: none;
        padding-bottom: 0;
      }
      .dot {
        width: 8px;
        height: 8px;
        background: var(--primary);
        border-radius: 50%;
        box-shadow: 0 0 10px var(--primary);
      }
      .content {
        flex: 1;
        display: flex;
        flex-direction: column;
      }
      .content strong {
        font-size: 0.95rem;
      }
      .content span {
        font-size: 0.85rem;
        color: var(--text-secondary);
      }
      .time {
        font-size: 0.8rem;
        color: var(--text-secondary);
      }
    `}</style>
  </div>
)

export default Dashboard
