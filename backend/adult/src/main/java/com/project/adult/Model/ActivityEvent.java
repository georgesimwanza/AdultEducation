package com.project.adult.Model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** One learner action, used to monitor participation (logins, lessons, submissions, messages). */
@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "activity_events",
        indexes = {
                @Index(name = "idx_activity_user_time", columnList = "user_id, created_at"),
                @Index(name = "idx_activity_course", columnList = "course_id")
        })
public class ActivityEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private Type type;

    @Column(name = "course_id")
    private Long courseId;

    @Column(length = 500)
    private String description;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public enum Type { LOGIN, VIEW_LESSON, SUBMIT_QUIZ, SUBMIT_ASSIGNMENT, SEND_MESSAGE, ENROLL }

    public ActivityEvent(Long userId, Type type, Long courseId, String description) {
        this.userId = userId;
        this.type = type;
        this.courseId = courseId;
        this.description = description;
        this.createdAt = LocalDateTime.now();
    }
}
