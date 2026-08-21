package com.project.adult.Model;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@EqualsAndHashCode(callSuper = true)
@Entity
@DiscriminatorValue("essay")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class EssayQuestion extends Question {

    private Integer minWords;
    private Integer maxWords;

    @Column(length = 1000)
    private String rubric;


    public EssayQuestion(String text, int points, String explanation, Integer minWords, Integer maxWords, String rubric) {
        super(text, points, explanation);
        this.minWords = minWords;
        this.maxWords = maxWords;
        this.rubric = rubric;
    }
}
