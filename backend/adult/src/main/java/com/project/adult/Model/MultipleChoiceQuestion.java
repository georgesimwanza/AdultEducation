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
@DiscriminatorValue("multipleChoice")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class MultipleChoiceQuestion extends Question {

    @ElementCollection
    @CollectionTable(name = "mcq_options", joinColumns = @JoinColumn(name = "question_id"))
    @OrderColumn(name = "option_order")
    @Column(name = "option_text", length = 500)
    private List<String> options = new ArrayList<>();

    @Column(name = "correct_option_index", nullable = false)
    private int correctOptionIndex;

    public MultipleChoiceQuestion(String text, int points, String explanation, List<String> options, int correctOptionIndex) {
        super(text, points, explanation);
        this.options = options;
        this.correctOptionIndex = correctOptionIndex;
    }
}
