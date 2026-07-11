package com.project.adult.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CreateQuizRequest {

    private String title;
    private String description = "";
    private Long courseId;
    private Long institutionId;
    private Integer timeLimitMinutes;
    private Integer passingScorePercent = 50;
    public void setTitle(String title) {
        this.title = title;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setCourseId(Long courseId) {
        this.courseId = courseId;
    }

    public void setInstitutionId(Long institutionId) {
        this.institutionId = institutionId;
    }
}
