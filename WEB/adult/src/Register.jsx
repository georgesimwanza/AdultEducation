import styles from './login.module.css';
import { useState } from 'react';
export default function Register() {

const [Firstname, setFirstname]= useState("");
const [Lastname, setLastname]= useState("");
const [Email, setEmail]= useState("");
const [PhoneNumber, setPhoneNumber]= useState("");
const [Password, setPassword] = useState("");
const [Programme, setProgramme] = useState("");

const handleSubmit = async (e) =>{
  e.preventDefault();
  const UserData ={
    Firstname:Firstname,
    Lastname: Lastname,
    Email: Email,
    Password : Password,
    PhoneNumber : PhoneNumber,
    Programme : Programme
  };

  try{
    const response = await fetch("http://localhost:8080/api/users/Register", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(UserData)
      });

      if (response.ok) {
        alert("User registered successfully");
      } else {
        alert("Registration failed");
      }
    } catch (error) {
      console.error(error);
      alert("Error connecting to server");
    }
  };

  return (
    <main className={styles.container}>
      <header className={styles.header}>
        <img src="cover.png" alt="Header Background" />
      </header>

      <form className={styles.card} onSubmit={handleSubmit}>
        <img src="logo.png" className={styles.logo} alt="Logo" />
        
        <h2>Create Account</h2>

        <input type="text" placeholder="Firstname" required value={Firstname}
        onChange={(e) => setFirstname(e.target.value)} />
        <input type="text" placeholder="Lastname" required  value={Lastname}
        onChange={(e) => setLastname(e.target.value)} />
        <input type="email" placeholder="Email Address" required value={Email} 
        onChange={(e) => setEmail(e.target.value)} />
        <input type="tel" placeholder="Phone PhoneNumber" required value={PhoneNumber} 
        onChange={(e) => setPhoneNumber(e.target.value)} />
        
        
        <select className={styles.selectField} required value={Programme}
        onChange={(e) => setProgramme(e.target.value)} >
          <option value="" disabled>Select Course to Enroll</option>
          <option value="cs">Computer Science</option>
          <option value="ba">Business Administration</option>
          <option value="design">Graphic Design</option>
        </select>

        <input type="password" placeholder="Password" required value={Password}
        onChange={(e) => setPassword(e.target.value)}  />

        <button type="submit" style={{ marginTop: '20px' }}>Register</button>

        <p className={styles.toggleText}>
          Already have an account? <a href="/login">Login</a>
        </p>
      </form>
    </main>
  );
}