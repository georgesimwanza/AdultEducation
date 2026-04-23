import { useState, useEffect } from 'react';
import styles from './coursedash.module.css';

export default function CourseDash() {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    try {
      const response = await fetch("http://localhost:8080/api/course/getAllCourses");
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      setCourses(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className={styles.container}>

      {/* Header */}
      <div className={styles.header}>
        <h2>Courses</h2>
        <button className={styles.addBtn}>+ Add New Course</button>
      </div>

      {/* Search */}
      <div className={styles.searchBox}>
        <input
          type="text"
          placeholder="Search Courses (Name, Code, Instructor)"
        />
      </div>

      {/* States */}
      {loading && <p>Loading courses...</p>}
      {error && <p style={{ color: 'red' }}>Error: {error}</p>}

      {/* Table */}
      {!loading && !error && (
        <table className={styles.table}>
          <thead>
            <tr>
              <th>Course Name</th>
              <th>Course Code</th>
              <th>Instructor</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {courses.map((course) => (
              <tr key={course.id}>
                <td>{course.crs_name}</td>
                <td>{course.crc_code}</td>
                <td>{course.crc_instructor}</td>
                <td className={styles.actions}>
                  <span className={styles.edit}>Edit</span>
                  <span className={styles.delete}>Delete</span>
                  <span className={styles.view}>View</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

    </div>
  );
}