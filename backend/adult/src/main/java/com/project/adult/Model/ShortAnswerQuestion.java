package com.project.adult.Model;

import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@DiscriminatorValue("shortAnswer")
public class ShortAnswerQuestion extends Question {

    @ElementCollection
    @CollectionTable(name = "short_answer_accepted", joinColumns = @JoinColumn(name = "question_id"))
    @Column(name = "answer_text", length = 500)
    private List<String> acceptedAnswers = new ArrayList<>();

    @Column(name = "case_sensitive", nullable = false)
    private boolean caseSensitive;

    protected ShortAnswerQuestion() {
        super();
    }

    public ShortAnswerQuestion(String text, int points, String explanation,
                                List<String> acceptedAnswers, boolean caseSensitive) {
        super(text, points, explanation);
        this.acceptedAnswers = acceptedAnswers;
        this.caseSensitive = caseSensitive;
    }

    public List<String> getAcceptedAnswers() {
        return acceptedAnswers;
    }

    public void setAcceptedAnswers(List<String> acceptedAnswers) {
        this.acceptedAnswers = acceptedAnswers;
    }

    public boolean isCaseSensitive() {
        return caseSensitive;
    }

    public void setCaseSensitive(boolean caseSensitive) {
        this.caseSensitive = caseSensitive;
    }
}
