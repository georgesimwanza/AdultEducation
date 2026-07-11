package com.project.adult.Model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Tracks a user's progress through a specific course.
 * Maps to the user_content_progress table.
 */
@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(
        name = "user_content_progress",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "course_id"})
)
public class UserContentProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnoreProperties({"contentProgresses", "institution", "selectedProgramme"})
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "course_id", nullable = false)
    @JsonIgnoreProperties({"userContentProgresses", "contents", "programmeCourses"})
    private Course course;

    @Column(name = "is_completed", nullable = false)
    private Boolean isCompleted = false;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "progress_percentage", nullable = false)
    private Short progressPercentage = 0;

    @Column(name = "last_accessed", nullable = false)
    private LocalDateTime lastAccessed = LocalDateTime.now();
}