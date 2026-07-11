package com.project.adult.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class QuizDto {

    private String id;
    private String title;
    private String description = "";
    private Long courseId;
    private Long institutionId;
    private List<QuestionDto> questions = new ArrayList<>();
    private Integer timeLimitMinutes;
    private int passingScorePercent = 50;

}
