package com.project.adult.DTO;


import lombok.Data;

@Data
public class ContentResponse {
    private Long id;
    private String title;
    private String type;
    private String fileUrl;
    private Long courseId;
    private Long institutionId;
}
