package com.project.adult.Model;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;

@Entity
@DiscriminatorValue("trueFalse")
public class TrueFalseQuestion extends Question {

    @Column(name = "correct_answer", nullable = false)
    private boolean correctAnswer;

    protected TrueFalseQuestion() {
        super();
    }

    public TrueFalseQuestion(String text, int points, String explanation, boolean correctAnswer) {
        super(text, points, explanation);
        this.correctAnswer = correctAnswer;
    }

    public boolean isCorrectAnswer() {
        return correctAnswer;
    }

    public void setCorrectAnswer(boolean correctAnswer) {
        this.correctAnswer = correctAnswer;
    }
}
