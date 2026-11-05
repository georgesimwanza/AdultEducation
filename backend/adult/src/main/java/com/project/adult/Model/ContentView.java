package com.project.adult.Model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Records that a learner opened a lesson (video, document, ...). Course
 * progress is the share of a course's lessons a learner has opened.
 */
@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "content_views",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "content_id"}),
        indexes = @Index(name = "idx_content_view_course", columnList = "course_id, user_id"))
public class ContentView {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "content_id")
    private Content content;

    // Copied from content.course so progress queries need no join
    @Column(name = "course_id", nullable = false)
    private Long courseId;

    @Column(name = "first_viewed_at", nullable = false)
    private LocalDateTime firstViewedAt = LocalDateTime.now();

    @Column(name = "last_viewed_at", nullable = false)
    private LocalDateTime lastViewedAt = LocalDateTime.now();

    @Column(name = "view_count", nullable = false)
    private Integer viewCount = 1;
}
