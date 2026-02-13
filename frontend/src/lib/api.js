import axios from "axios";

const API_BASE = process.env.REACT_APP_BACKEND_URL;

const api = axios.create({
  baseURL: `${API_BASE}/api`,
  headers: { "Content-Type": "application/json" },
});

// Attach token to every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("sfm_token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle 401
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem("sfm_token");
      localStorage.removeItem("sfm_user");
      window.location.href = "/login";
    }
    return Promise.reject(err);
  }
);

export default api;
