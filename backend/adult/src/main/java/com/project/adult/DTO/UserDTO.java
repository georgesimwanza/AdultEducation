package com.project.adult.DTO;


import lombok.Data;

@Data
public class UserDTO {
    private String firstName;
    private String lastName;
    private String email;
    private Long programmeId;
    private String programmeName;
    private String token;
    private String role;
    private String institutionName;
    private Long institutionId;
    public UserDTO(String firstName, String lastName, String email,
                   Long programmeId, String programmeName, String token, String role, Long institutionId, String institutionName) {
        this.firstName     = firstName;
        this.lastName      = lastName;
        this.email         = email;
        this.programmeId   = programmeId;
        this.programmeName = programmeName;
        this.token         = token;
        this.role         = role;
        this.institutionId = institutionId;
        this.institutionName = institutionName;
    }

}