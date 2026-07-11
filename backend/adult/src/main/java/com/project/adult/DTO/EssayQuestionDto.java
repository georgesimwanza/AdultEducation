package com.project.adult.DTO;


import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@EqualsAndHashCode(callSuper = true)
@Data
@AllArgsConstructor
@NoArgsConstructor
public class EssayQuestionDto extends QuestionDto {

    private Integer minWords;
    private Integer maxWords;
    private String rubric;
}
