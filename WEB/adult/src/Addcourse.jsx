import { useState } from "react";
import styles from "./AddCourse.module.css";

export default function AddCourse() {

  const [formData, setFormData] = useState({
    courseName: "",
    courseCode: "",
    instructor: ""
  });

  const handleChange = (e) => {
    const { name, value } = e.target;

    setFormData({
      ...formData,
      [name]: value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      const response = await fetch("http://localhost:8080/api/course/addCourse", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(formData)
      });

      if (response.ok) {
        alert("Course added successfully");
      } else {
        alert("Registration failed");
      }
    } catch (error) {
      console.error(error);
      alert("Failed to connect to the server");
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <h2 className={styles.title}>Add New Course</h2>

        <form className={styles.form} onSubmit={handleSubmit}>

          <div className={styles.inputGroup}>
            <label>Course Name</label>
            <input
              type="text"
              name="courseName"
              value={formData.courseName}
              onChange={handleChange}
              required
            />
          </div>

          <div className={styles.inputGroup}>
            <label>Course Code</label>
            <input
              type="text"
              name="courseCode"
              value={formData.courseCode}
              onChange={handleChange}
              required
            />
          </div>

          <div className={styles.inputGroup}>
            <label>Instructor</label>
            <input
              type="text"
              name="instructor"
              value={formData.instructor}
              onChange={handleChange}
              required
            />
          </div>

          <button type="submit" className={styles.button}>
            Add Course
          </button>

        </form>
      </div>
    </div>
  );
}