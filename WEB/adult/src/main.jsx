import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'
import Login from './loginpage.jsx'
import Register from './Register.jsx'
import CourseDash from './coursedashboard.jsx'
import AddCourse from './Addcourse.jsx'
createRoot(document.getElementById('root')).render(
  <StrictMode>
    <CourseDash/>
  </StrictMode>,
)
