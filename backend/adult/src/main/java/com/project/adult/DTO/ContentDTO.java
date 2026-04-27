package com.project.adult.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class ContentDTO {
    private long id;
    private String type;
    private String title;
    private String file_Url;
}
