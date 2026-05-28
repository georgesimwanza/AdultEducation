package com.project.adult.DTO;


import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class SubjectDTO {
    private Long id;
    private String CourseCode;
    private String courseName;
    private String description;
    private Long programmeId;
}


