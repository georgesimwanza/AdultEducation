package com.project.adult.Model;

import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@DiscriminatorValue("multipleChoice")
public class MultipleChoiceQuestion extends Question {

    @ElementCollection
    @CollectionTable(name = "mcq_options", joinColumns = @JoinColumn(name = "question_id"))
    @OrderColumn(name = "option_order")
    @Column(name = "option_text", length = 500)
    private List<String> options = new ArrayList<>();

    @Column(name = "correct_option_index", nullable = false)
    private int correctOptionIndex;

    protected MultipleChoiceQuestion() {
        super();
    }

    public MultipleChoiceQuestion(String text, int points, String explanation,
                                   List<String> options, int correctOptionIndex) {
        super(text, points, explanation);
        this.options = options;
        this.correctOptionIndex = correctOptionIndex;
    }

    public List<String> getOptions() {
        return options;
    }

    public void setOptions(List<String> options) {
        this.options = options;
    }

    public int getCorrectOptionIndex() {
        return correctOptionIndex;
    }

    public void setCorrectOptionIndex(int correctOptionIndex) {
        this.correctOptionIndex = correctOptionIndex;
    }
}
