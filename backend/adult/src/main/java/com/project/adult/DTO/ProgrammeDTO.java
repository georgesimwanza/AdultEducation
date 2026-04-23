package com.project.adult.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
// ProgrammeDTO.java
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProgrammeDTO {
    private Long id;
    private String name;
    private String description;
}