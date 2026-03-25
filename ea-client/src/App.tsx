import { useState, useEffect, useRef } from 'react'
import './index.css'

interface ModalData {
  isOpen: boolean;
  type: 'success' | 'warning' | 'error';
  title: string;
  message: string;
}

interface EaInfo {
  connected: boolean;
  version: string;
  latestVersion: string;
  symbol: string;
  updateAvailable: boolean;
}

function App() {
  const [ticks, setTicks] = useState<any[]>([])
  const [status, setStatus] = useState('Disconnected')
  const [modal, setModal] = useState<ModalData>({ isOpen: false, type: 'success', title: '', message: '' })
  const [eaInfo, setEaInfo] = useState<EaInfo>({ connected: false, version: '-', latestVersion: '-', symbol: '', updateAvailable: false })
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

        if (data.type === 'welcome') {
          setEaInfo({
            connected: data.ea_connected || false,
            version: data.ea_version || '-',
            latestVersion: data.latest_ea_version || '-',
            symbol: data.ea_symbol || '',
            updateAvailable: data.update_available || false,
          })
        }

        if (data.type === 'ea_info') {
          setEaInfo({
            connected: true,
            version: data.version,
            latestVersion: data.latest_version,
            symbol: data.symbol,
            updateAvailable: data.update_available,
          })
          setStatus('Connected (EA v' + data.version + ')')
        }

        if (data.type === 'tick') {
          setTicks((prev) => [data, ...prev].slice(0, 15))
        }

        if (data.type === 'deploy_status') {
          if (data.status === 'already_connected') {
            setModal({ isOpen: true, type: 'success', title: 'EA Already Running', message: 'EA is already connected and running the latest version. No update needed!' })
          } else if (data.status === 'update_available') {
            setModal({ isOpen: true, type: 'warning', title: 'Update Available', message: `Current: v${data.current_version} → Latest: v${data.latest_version}. Click "Update EA" to push the new version!` })
          } else if (data.status === 'success') {
            setModal({ isOpen: true, type: 'success', title: 'Deployment Successful', message: 'EA deployed and MT5 is launching...' })
          } else {
            setModal({ isOpen: true, type: 'error', title: 'Deployment Failed', message: 'Could not find MT5 directory.' })
          }
        }

        if (data.type === 'update_status') {
          if (data.status === 'success') {
            setModal({ isOpen: true, type: 'success', title: 'EA Updated!', message: `EA has been updated to v${data.latest_version}. MT5 is restarting...` })
            setEaInfo(prev => ({ ...prev, updateAvailable: false, version: data.latest_version }))
          } else {
            setModal({ isOpen: true, type: 'error', title: 'Update Failed', message: 'Failed to update EA files.' })
          }
        }

      } catch (e) {
        console.error(e)
      }
    }

    ws.onclose = () => {
      setStatus('Disconnected')
      setEaInfo({ connected: false, version: '-', latestVersion: '-', symbol: '', updateAvailable: false })
      setTimeout(connect, 3000)
    }
  }

  const handlePanic = () => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ action: 'panic' }))
    }
  }

  const deployEa = () => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ action: 'deploy_ea' }))
    }
  }

  const updateEa = () => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ action: 'update_ea' }))
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

        {/* EA Version Info */}
        <div className="sidebar-footer">
          <div className="ea-version-info">
            <div className="version-label">EA Version</div>
            <div className="version-value">
              <span className={`version-dot ${eaInfo.connected ? 'online' : 'offline'}`}></span>
              {eaInfo.connected ? `v${eaInfo.version}` : 'Not Connected'}
            </div>
            <div className="version-label" style={{marginTop: '4px'}}>Latest: v{eaInfo.latestVersion}</div>
          </div>
        </div>
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

        {/* Update Available Banner */}
        {eaInfo.updateAvailable && (
          <div className="update-banner">
            <div className="update-banner-text">
              🔄 <strong>EA Update Available!</strong> Current: v{eaInfo.version} → Latest: v{eaInfo.latestVersion}
            </div>
            <button className="update-btn" onClick={updateEa}>
              ⬆️ Update EA Now
            </button>
          </div>
        )}

        <main className="content">
          <div className="header-actions">
            <h2>Active Markets</h2>
            <div style={{ display: 'flex', gap: '12px' }}>
              <button className="panic-btn deploy-btn" onClick={deployEa}>
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
              {modal.type === 'warning' && eaInfo.updateAvailable && (
                <button className="modal-btn update-modal-btn" onClick={() => { updateEa(); closeModal(); }}>
                  ⬆️ Update Now
                </button>
              )}
              <button className="modal-btn" onClick={closeModal}>OK</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default App
