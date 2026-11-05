package com.project.adult.Model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** Coursework (an assignment or a test) set by an instructor, with a deadline. */
@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "assignments",
        indexes = {
                @Index(name = "idx_assignment_course", columnList = "course_id"),
                @Index(name = "idx_assignment_due", columnList = "due_date")
        })
public class Assignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "course_id")
    private Course course;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "institution_id")
    private Institution institution;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    // ASSIGNMENT or TEST; both are submitted and graded the same way
    @Column(nullable = false, length = 20)
    private String kind = "ASSIGNMENT";

    @Column(name = "due_date", nullable = false)
    private LocalDateTime dueDate;

    @Column(name = "max_score", nullable = false)
    private Integer maxScore = 100;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private User createdBy;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    // Set once the "due soon" reminder has gone out, so it is only sent once
    @Column(name = "reminder_sent", nullable = false)
    private Boolean reminderSent = false;
}
