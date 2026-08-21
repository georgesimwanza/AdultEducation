package com.project.adult.Model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@EqualsAndHashCode(callSuper = true)
@Entity
@DiscriminatorValue("shortAnswer")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ShortAnswerQuestion extends Question {

    @ElementCollection
    @CollectionTable(name = "short_answer_accepted", joinColumns = @JoinColumn(name = "question_id"))
    @Column(name = "answer_text", length = 500)
    private List<String> acceptedAnswers = new ArrayList<>();

    @Column(name = "case_sensitive", nullable = false)
    private boolean caseSensitive;

    public ShortAnswerQuestion(String text, int points, String explanation, List<String> acceptedAnswers, Boolean caseSensitive) {
        super(text, points, explanation);
        this.acceptedAnswers = acceptedAnswers;
        this.caseSensitive = caseSensitive;
    }
}
