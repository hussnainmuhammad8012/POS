import React from 'react'
import { Users, CreditCard, ShieldAlert, MessageSquare } from 'lucide-react'

const Dashboard = () => {
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
          value="124" 
          trend="+12% this month" 
        />
        <StatCard 
          icon={<CreditCard color="#22c55e" />} 
          label="Active Trials" 
          value="45" 
          trend="+5 new today" 
        />
        <StatCard 
          icon={<ShieldAlert color="#ef4444" />} 
          label="Blocked Accounts" 
          value="3" 
          trend="No change" 
        />
        <StatCard 
          icon={<MessageSquare color="#f59e0b" />} 
          label="Pending Feedback" 
          value="8" 
          trend="2 urgent" 
        />
      </div>

      <div className="recent-activity glass">
        <h3>Recent Activity</h3>
        <div className="activity-list">
          <ActivityItem label="New client registered" time="2 hours ago" client="Al-Madina Store" />
          <ActivityItem label="Trial expired" time="5 hours ago" client="Sunny Electronics" />
          <ActivityItem label="Feedback received" time="yesterday" client="General Bakers" />
        </div>
      </div>

      <style jsx>{`
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
    <style jsx>{`
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
    <style jsx>{`
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
