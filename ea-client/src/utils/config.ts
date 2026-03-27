export const getWsUrl = (): string => {
  const savedUrl = localStorage.getItem('ea24_server_url');
  if (savedUrl) return savedUrl;
  
  const host = import.meta.env.VITE_WS_HOST || window.location.hostname;
  return `ws://${host}:8080`;
};

export const setWsUrl = (url: string) => {
  localStorage.setItem('ea24_server_url', url);
};
