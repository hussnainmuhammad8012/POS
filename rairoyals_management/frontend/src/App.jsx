import React, { useState } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import Navbar from './components/Navbar'
import Sidebar from './components/Sidebar'
import Dashboard from './pages/Dashboard'
import Clients from './pages/Clients'
import Feedback from './pages/Feedback'
import Login from './pages/Login'

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  if (!isAuthenticated) {
    return <Login onLogin={() => setIsAuthenticated(true)} />;
  }

  return (
    <Router>
      <div className="app-container">
        <Sidebar />
        <div className="main-content">
          <Navbar />
          <div className="page-content">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/clients" element={<Clients />} />
              <Route path="/feedback" element={<Feedback />} />
              <Route path="*" element={<Navigate to="/" />} />
            </Routes>
          </div>
        </div>
      </div>
      <style>{`
        .app-container {
          display: flex;
          min-height: 100vh;
        }
        .main-content {
          flex: 1;
          display: flex;
          flex-direction: column;
          margin-left: 260px;
        }
        .page-content {
          padding: 2rem;
          max-width: 1400px;
          width: 100%;
          margin: 0 auto;
        }
      `}</style>
    </Router>
  )
}

export default App
