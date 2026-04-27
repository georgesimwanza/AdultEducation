import { useState } from "react";
import styles from "./content.module.css";

export default function AddContent() {
  const [title, setTitle] = useState("");
  const [type, setType] = useState("Article");
  const [fileName, setFileName] = useState("");

  const types = ["Article", "Video", "Podcast"];

  const handleFile = (file) => {
    if (file) setFileName(file.name);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    handleFile(e.dataTransfer.files[0]);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();   
    const contentData = { title, type, fileName };

    try {
      const response = await fetch("http://localhost:8080/api/Content/addContent", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(contentData),
      });

      if (response.ok) {
        alert("Content added successfully");
      } else {
        alert("Failed to add content");
      }
    } catch (error) {
      console.error(error);
      alert("Error connecting to server");
    }
  };

  return (
    <form className={styles.card} onSubmit={handleSubmit}>   {/* ✅ form tag */}
      <div className={styles.header}>
        <span className={styles.tag}>New Entry</span>
        <h2 className={styles.title}>Add Content</h2>
      </div>

      <div className={styles.field}>
        <label className={styles.label}>Title</label>
        <input
          className={styles.input}
          type="text"
          placeholder="Enter a title…"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />
      </div>

      <div className={styles.field}>
        <label className={styles.label}>Attachment</label>
        <div
          className={styles.dropZone}
          onDragOver={(e) => e.preventDefault()}
          onDrop={handleDrop}
          onClick={() => document.getElementById("fileInput").click()}
        >
          <input
            id="fileInput"
            type="file"
            style={{ display: "none" }}
            onChange={(e) => handleFile(e.target.files[0])}
          />
          <div className={styles.dropIcon}>⬆</div>
          <p className={styles.dropText}>
            Drop file or <span className={styles.dropLink}>browse</span>
          </p>
          <p className={styles.dropHint}>PDF · PNG · MP4 — max 50 MB</p>
        </div>
        {fileName && <div className={styles.fileName}>📄 {fileName}</div>}
      </div>

      <div className={styles.field}>
        <label className={styles.label}>Type</label>
        <div className={styles.typeRow}>
          {types.map((t) => (
            <button
              key={t}
              type="button"                   // ✅ prevents accidental form submit
              className={`${styles.typeBtn} ${type === t ? styles.active : ""}`}
              onClick={() => setType(t)}
            >
              {t}
            </button>
          ))}
        </div>
      </div>

      <div className={styles.divider} />

      <button type="submit" className={styles.submitBtn}>  {/* ✅ type submit */}
        Add Content
      </button>
    </form>
  );
}