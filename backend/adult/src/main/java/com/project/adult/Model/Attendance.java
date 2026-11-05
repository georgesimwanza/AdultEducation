package com.project.adult.Model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * One learner's attendance for one course on one day. Instructors mark it
 * by hand (MANUAL); watching a video lesson marks the learner present
 * automatically (AUTO) unless an instructor already recorded that day.
 */
@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "attendance",
        uniqueConstraints = @UniqueConstraint(columnNames = {"course_id", "learner_id", "session_date"}),
        indexes = @Index(name = "idx_attendance_learner", columnList = "learner_id"))
public class Attendance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "course_id")
    private Course course;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "learner_id")
    private User learner;

    @Column(name = "session_date", nullable = false)
    private LocalDate sessionDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Status status;

    @Column(nullable = false, length = 10)
    private String source = "MANUAL";

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recorded_by")
    private User recordedBy;

    @Column(name = "recorded_at", nullable = false)
    private LocalDateTime recordedAt = LocalDateTime.now();

    public enum Status { PRESENT, ABSENT, LATE, EXCUSED }
}
