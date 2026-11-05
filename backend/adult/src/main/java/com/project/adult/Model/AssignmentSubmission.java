package com.project.adult.Model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** A learner's answer to an assignment, plus the instructor's grade and feedback. */
@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "assignment_submissions",
        uniqueConstraints = @UniqueConstraint(columnNames = {"assignment_id", "learner_id"}))
public class AssignmentSubmission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "assignment_id")
    private Assignment assignment;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "learner_id")
    private User learner;

    @Column(name = "answer_text", columnDefinition = "TEXT")
    private String answerText;

    @Column(name = "file_url", length = 1000)
    private String fileUrl;

    @Column(name = "submitted_at", nullable = false)
    private LocalDateTime submittedAt = LocalDateTime.now();

    private Integer score;

    @Column(columnDefinition = "TEXT")
    private String feedback;

    @Column(name = "graded_at")
    private LocalDateTime gradedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "graded_by")
    private User gradedBy;
}
