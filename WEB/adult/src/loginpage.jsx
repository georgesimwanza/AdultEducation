import styles from './login.module.css';

export default function Login() {
  return (
    <main className={styles.container}>
     
      <header className={styles.header}>
        <img src="cover.png" alt="Header Background" />
      </header>

      <form className={styles.card}>
        <img src="logo.png" className={styles.logo} alt="Logo" />
        
        <h2>Login</h2>
        
        <input type="text" placeholder="Username" required />
        <input type="password" placeholder="Password" required />

        <div className={styles.remember}>
          <input type="checkbox" id="remember" />
          <label htmlFor="remember">Remember Me</label>
        </div>

        <button type="submit">Login</button>
        
        <p className={styles.toggleText}>
          Don't have an account? <a href="/register">Register</a>
        </p>
      </form>
    </main>
  );
}