import { useState, useEffect, useRef } from 'react'
import './index.css'

interface ModalData {
  isOpen: boolean;
  type: 'success' | 'warning' | 'error';
  title: string;
  message: string;
}

function App() {
  const [ticks, setTicks] = useState<any[]>([])
  const [status, setStatus] = useState('Disconnected')
  const [modal, setModal] = useState<ModalData>({ isOpen: false, type: 'success', title: '', message: '' })
  const wsRef = useRef<WebSocket | null>(null)

  useEffect(() => {
    connect()
    return () => {
      if (wsRef.current) wsRef.current.close()
    }
  }, [])

  const connect = () => {
    setStatus('Connecting...')
    const ws = new WebSocket('ws://127.0.0.1:8080')
    wsRef.current = ws

    ws.onopen = () => {
      setStatus('Connected')
    }

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        if (data.type === 'tick') {
          setTicks((prev) => {
            const newTicks = [data, ...prev].slice(0, 15)
            return newTicks
          })
        } else if (data.type === 'deploy_status') {
          if (data.status === 'already_connected') {
            setModal({
              isOpen: true,
              type: 'warning',
              title: 'EA Already Running',
              message: 'The Expert Advisor is already connected and streaming live data. No need to deploy again!'
            })
            setStatus('Connected (EA Active)')
          } else if (data.status === 'success') {
            setModal({
              isOpen: true,
              type: 'success',
              title: 'Deployment Successful',
              message: 'EA has been deployed and MT5 is automatically launching the chart. Please wait a moment...'
            })
            setStatus('Connected (Waiting for EA)')
          } else {
            setModal({
              isOpen: true,
              type: 'error',
              title: 'Deployment Failed',
              message: 'Could not find standard MT5 directory. Please attach the EA manually.'
            })
            setStatus('Connected')
          }
        }
      } catch (e) {
        console.error(e)
      }
    }

    ws.onclose = () => {
      setStatus('Disconnected')
      setTimeout(connect, 3000)
    }
  }

  const handlePanic = () => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ action: 'panic' }))
    }
  }

  const deployEa = () => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ action: 'deploy_ea' }))
      setStatus('Deploying EA...')
    }
  }

  const closeModal = () => setModal({ ...modal, isOpen: false })

  const getStatusClass = () => {
    if (status.includes('Connected')) return 'connected'
    if (status.includes('Connecting')) return 'connecting'
    return 'disconnected'
  }

  return (
    <div className="docker-layout">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="logo">🐳 EA Trading</div>
        </div>
        <nav className="sidebar-nav">
          <a href="#" className="nav-item active">
            <span className="icon">📊</span> Containers (Prices)
          </a>
          <a href="#" className="nav-item">
            <span className="icon">💿</span> Images (History)
          </a>
          <a href="#" className="nav-item">
            <span className="icon">🗄️</span> Volumes (Storage)
          </a>
          <a href="#" className="nav-item">
            <span className="icon">⚙️</span> Settings
          </a>
        </nav>
      </aside>

      {/* Main UI */}
      <div className="main-wrapper">
        <header className="topbar">
          <div className="search-bar">
            <input type="text" placeholder="Search (Ctrl+K)" readOnly />
          </div>
          <div className="topbar-actions">
            <div className={`status-badge ${getStatusClass()}`}>
              <div className="status-dot"></div>
              {status}
            </div>
          </div>
        </header>

        <main className="content">
          <div className="header-actions">
            <h2>Active Markets</h2>
            <div style={{ display: 'flex', gap: '12px' }}>
              <button 
                className="panic-btn deploy-btn" 
                onClick={deployEa}
              >
                <span className="icon">📦</span> DEPLOY EA TO MT5
              </button>
              <button className="panic-btn" onClick={handlePanic}>
                <span className="icon">⛔</span> CLOSE ALL (PANIC)
              </button>
            </div>
          </div>

          <div className="card data-card">
            <div className="data-table-wrapper">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Symbol</th>
                    <th>Bid</th>
                    <th>Ask</th>
                    <th>Spread</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {ticks.map((tick, idx) => (
                    <tr key={idx}>
                      <td className="symbol-cell">
                        <span className="docker-icon">📦</span> {tick.symbol}
                      </td>
                      <td className="bid-cell">{tick.bid.toFixed(2)}</td>
                      <td className="ask-cell">{tick.ask.toFixed(2)}</td>
                      <td>
                        <span className="spread-badge">{tick.spread.toFixed(2)}</span>
                      </td>
                      <td>
                        <span className="running-badge">Running</span>
                      </td>
                    </tr>
                  ))}
                  {ticks.length === 0 && (
                    <tr>
                      <td colSpan={5} className="empty-state">
                        Waiting for market data...
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </main>
      </div>

      {/* Custom Modal */}
      {modal.isOpen && (
        <div className="modal-overlay">
          <div className={`modal-content ${modal.type}`}>
            <div className="modal-header">
              <div className="modal-icon">
                {modal.type === 'success' && '✅'}
                {modal.type === 'warning' && '⚠️'}
                {modal.type === 'error' && '❌'}
              </div>
              <h3 className="modal-title">{modal.title}</h3>
            </div>
            <div className="modal-body">
              <p>{modal.message}</p>
            </div>
            <div className="modal-footer">
              <button className="modal-btn" onClick={closeModal}>OK</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default App
