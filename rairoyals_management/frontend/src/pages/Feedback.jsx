import React, { useState, useEffect } from 'react'
import { MessageSquare, Smile, Frown, Meh, ExternalLink, CheckCircle, Image as ImageIcon } from 'lucide-react'
import api from '../api'

const Feedback = () => {
  const [feedback, setFeedback] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchFeedback();
  }, []);

  const fetchFeedback = async () => {
    try {
      const response = await api.get('/feedback'); // Matches router.get('/feedback', ...)
      setFeedback(response.data);
    } catch (err) {
      console.error('Error fetching feedback:', err);
    } finally {
      setLoading(false);
    }
  };

  const getSentimentIcon = (type) => {
    switch(type) {
      case 'positive': return <Smile color="#22c55e" size={20} />;
      case 'negative': return <Frown color="#ef4444" size={20} />;
      default: return <Meh color="#f59e0b" size={20} />;
    }
  };

  return (
    <div className="feedback-page animate-fade-in">
      <header className="page-header">
        <h1>User Feedback</h1>
        <p>Listen to your clients and improve the experience.</p>
      </header>

      <div className="feedback-grid">
          {feedback.map(item => (
            <div key={item._id} className={`feedback-card glass ${item.isProcessed ? 'processed' : ''}`}>
              <div className="card-header">
                <div className="client-meta">
                  {getSentimentIcon(item.sentiment)}
                  <div>
                    <h4>{item.storeName || 'Unknown Store'}</h4>
                    <span>{item.clientName || 'Staff'} • {new Date(item.createdAt).toLocaleString()}</span>
                  </div>
                </div>
                <div className="status-indicator">
                  {item.isProcessed ? <CheckCircle size={18} color="var(--success)" /> : <span className="new-badge">New</span>}
                </div>
              </div>
              
              <div className="card-body">
                <p>{item.content}</p>
              </div>

              <div className="card-footer">
                {item.attachments && item.attachments.length > 0 && (
                  <a href={`http://localhost:5000/${item.attachments[0]}`} target="_blank" rel="noopener noreferrer" className="view-attachments-btn">
                    <ImageIcon size={16} />
                    <span>View Attachment</span>
                  </a>
                )}
                {!item.isProcessed && (
                  <button className="mark-processed-btn">Mark as Processed</button>
                )}
              </div>
            </div>
          ))}
      </div>

      <style>{`
        .page-header {
          margin-bottom: 2.5rem;
        }
        .feedback-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
          gap: 1.5rem;
        }
        .feedback-card {
          padding: 1.8rem;
          border-radius: 20px;
          display: flex;
          flex-direction: column;
          gap: 1.5rem;
        }
        .feedback-card.processed {
          opacity: 0.7;
          background: rgba(255, 255, 255, 0.02);
        }
        .card-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
        }
        .client-meta {
          display: flex;
          gap: 1rem;
        }
        .client-meta h4 {
          font-size: 1.1rem;
        }
        .client-meta span {
          font-size: 0.8rem;
          color: var(--text-secondary);
        }
        .new-badge {
          background: var(--primary);
          color: white;
          font-size: 0.7rem;
          padding: 0.2rem 0.6rem;
          border-radius: 4px;
          font-weight: 700;
          text-transform: uppercase;
        }
        .card-body p {
          color: var(--text-primary);
          font-size: 0.95rem;
          line-height: 1.6;
        }
        .card-footer {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-top: auto;
          padding-top: 1rem;
          border-top: 1px solid rgba(255, 255, 255, 0.05);
        }
        .view-attachments-btn {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          background: transparent;
          color: var(--primary);
          font-size: 0.9rem;
          font-weight: 600;
        }
        .mark-processed-btn {
          padding: 0.5rem 1rem;
          background: rgba(255, 255, 255, 0.05);
          color: var(--text-primary);
          border-radius: 8px;
          font-size: 0.85rem;
          font-weight: 600;
        }
        .mark-processed-btn:hover {
          background: var(--success);
          color: white;
        }
      `}</style>
    </div>
  )
}

export default Feedback
