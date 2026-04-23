package com.project.adult.Model;

import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@Embeddable
@AllArgsConstructor
@NoArgsConstructor
public class ProgrammeCourseId implements Serializable {

    private Long programmeId;
    private Long courseId;
}
