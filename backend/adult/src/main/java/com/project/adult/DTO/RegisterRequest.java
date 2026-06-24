package com.project.adult.DTO;

import com.project.adult.Model.Institution;
import lombok.Data;

@Data
public class RegisterRequest {
    private String firstName;
    private String lastName;
    private String email;
    private String passwordHash;
    private ProgrammeRef selectedProgramme;
    private Long  institutionId;

    @Data
    public static class ProgrammeRef {
        private Long id;
    }
}