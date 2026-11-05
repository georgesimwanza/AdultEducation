package com.project.adult.Model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** An in-app notification for one user: deadlines, grades, announcements, messages. */
@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "notifications",
        indexes = @Index(name = "idx_notification_user", columnList = "user_id, created_at"))
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Type type;

    @Column(nullable = false)
    private String title;

    @Column(length = 1000)
    private String body;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "read_at")
    private LocalDateTime readAt;

    public enum Type { DEADLINE, GRADE, ANNOUNCEMENT, MESSAGE, COURSE, SYSTEM }
}
