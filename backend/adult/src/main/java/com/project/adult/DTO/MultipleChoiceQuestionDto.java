package com.project.adult.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.util.List;
@EqualsAndHashCode(callSuper = true)
@Data
@AllArgsConstructor
@NoArgsConstructor
public class MultipleChoiceQuestionDto extends QuestionDto {

    private List<String> options;
    private int correctOptionIndex;

}
