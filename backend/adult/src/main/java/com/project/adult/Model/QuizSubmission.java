package com.project.adult.Model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * A student's submitted answers for a quiz, pushed up once the device is
 * back online. Answers are stored as a JSON string ({@code questionId ->
 * selected answer}) rather than a fully normalized table, since the
 * {@code Question} entity's answer-option shape wasn't available when this
 * was written — replace {@code answersJson} with a proper relation once
 * you're ready to compute/verify scores server-side.
 */
@Entity
@Table(name = "Quiz_submissions")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class QuizSubmission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long quizId;

    /**
     * Identifies the student. Matches the email-based identity already used
     * for schedules on the Flutter side — swap for a real Student FK if you
     * have one.
     */
    @Column(nullable = false)
    private String studentEmail;

    @Column(length = 5000, nullable = false)
    private String answersJson;

    /** Optional — set by the client if it self-scores, otherwise null. */
    private Integer score;

    @Column(nullable = false)
    private LocalDateTime submittedAt;
}