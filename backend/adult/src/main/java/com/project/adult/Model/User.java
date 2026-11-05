package com.project.adult.Model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "uuid", unique = true, nullable = false, updatable = false)
    private java.util.UUID uuid;

    @Column(name = "first_name", nullable = false, length = 100)
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 100)
    private String lastName;

    @Column(name = "email", unique = true, nullable = false, length = 255)
    private String email;

    // Never serialised: user lists are returned to the admin screens as JSON
    @JsonIgnore
    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    private Role role;

    // ── Learner profile ──────────────────────────────────────────────
    // Phone, date of birth and address are personal data, so they are
    // encrypted at rest (AES-GCM) by EncryptedStringConverter.
    @Convert(converter = com.project.adult.Security.EncryptedStringConverter.class)
    @Column(name = "phone_number", length = 512)
    private String phoneNumber;

    @Convert(converter = com.project.adult.Security.EncryptedStringConverter.class)
    @Column(name = "date_of_birth", length = 512)
    private String dateOfBirth;

    @Convert(converter = com.project.adult.Security.EncryptedStringConverter.class)
    @Column(name = "address", length = 1024)
    private String address;

    @Column(name = "gender", length = 20)
    private String gender;

    // e.g. "No formal schooling", "Primary", "Secondary", "Certificate", "Diploma", "Degree"
    @Column(name = "education_level", length = 100)
    private String educationLevel;

    @Column(name = "occupation", length = 150)
    private String occupation;

    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt;
    @ManyToOne(fetch = FetchType.LAZY)
    @JsonIgnore
    @JoinColumn(name = "selected_programme_id")
    private Programme selectedProgramme;

    @Column(name = "is_active", nullable = true)
    private Boolean isActive = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    // Relationship to user_content_progress
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<UserContentProgress> contentProgresses;

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
    @PrePersist
    public void prePersist() {
        if (this.uuid == null) this.uuid = java.util.UUID.randomUUID();
        if (this.role == null) this.role= Role.USER;
        if (this.isActive == null) this.isActive = true;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }
    @ManyToOne
    @JsonBackReference
    @JoinColumn(name = "institution_id")
    private Institution institution;

    public enum Role{
        // USER is a learner; INSTRUCTOR teaches courses and grades work
        USER,ADMIN,INSTITUTION,INSTRUCTOR
    }
}