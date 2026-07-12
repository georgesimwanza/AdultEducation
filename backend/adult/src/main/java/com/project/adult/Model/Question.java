package com.project.adult.Model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Base entity for every quiz question. Uses SINGLE_TABLE inheritance with
 * a "question_type" discriminator, mirroring the sealed Question class on
 * the Flutter side. The bidirectional link to Quiz below is intentional —
 * it's what makes cascade/orphanRemoval work — but this entity is never
 * serialized directly by Jackson. All API traffic goes through QuestionDto
 * (see QuizMapper), so the recursion problem you've hit before with
 * bidirectional JPA relations doesn't apply here.
 */
@Entity
@Table(name = "questions")
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "question_type", discriminatorType = DiscriminatorType.STRING)
@Data
@AllArgsConstructor
@NoArgsConstructor
public abstract class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 2000)
    private String text;

    @Column(nullable = false)
    private int points = 1;

    @Column(length = 1000)
    private String explanation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "quiz_id", nullable = false)
    @JsonIgnoreProperties({"questions", "course", "institution", "hibernateLazyInitializer", "handler"})
    private Quiz quiz;


    public Question(String text, int points, String explanation) {
    }
}
