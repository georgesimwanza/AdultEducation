package com.project.adult.DTO;

import lombok.Data;

@Data
public class RegisterRequest {
    private String firstName;
    private String lastName;
    private String email;
    private String passwordHash;
    private ProgrammeRef selectedProgramme;

    @Data
    public static class ProgrammeRef {
        private Long id;
    }
}