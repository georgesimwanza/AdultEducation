package com.project.adult.Model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
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
@Table(name = "courses")
public class Course {

   @Id
   @GeneratedValue(strategy = GenerationType.IDENTITY)
   private Long id;

   @Column(columnDefinition = "uuid DEFAULT uuid_generate_v4()", unique = true, nullable = false, updatable = false)
   private java.util.UUID uuid;

   @Column(name = "course_code", unique = true, nullable = false, length = 50)
   private String courseCode;

   @Column(name = "name", nullable = false, length = 255)
   private String name;

   @Column(name = "description", columnDefinition = "TEXT")
   private String description;

   @Column(name = "category", length = 100)
   private String category;

   @Column(name = "level", length = 50)
   private String level;

   @Column(name = "credits", nullable = false)
   private Integer credits = 1;

   @Column(name = "hours_per_week")
   private Integer hoursPerWeek;

   @Column(name = "is_mandatory", nullable = false)
   private Boolean isMandatory = false;

   @Column(name = "is_active", nullable = false)
   private Boolean isActive = true;

   @Column(name = "created_at", nullable = false, updatable = false)
   private LocalDateTime createdAt;

   @Column(name = "updated_at", nullable = false)
   private LocalDateTime updatedAt;

   @JsonBackReference
   @JsonIgnoreProperties("course")
   @OneToMany(mappedBy = "course", cascade = CascadeType.ALL)
   private List<ProgrammeCourse> programmeCourses;

   @JsonIgnoreProperties("course")
   @OneToMany(mappedBy = "course", cascade = CascadeType.ALL)
   private List<UserContentProgress> userContentProgresses;

   @JsonIgnoreProperties("course")
   @OneToMany(mappedBy = "course", cascade = CascadeType.ALL, orphanRemoval = true)
   private List<Content> contents;

   @PrePersist
   protected void onCreate() {
      this.createdAt = LocalDateTime.now();
      this.updatedAt = LocalDateTime.now();
   }

   @PreUpdate
   protected void onUpdate() {
      this.updatedAt = LocalDateTime.now();
   }
}