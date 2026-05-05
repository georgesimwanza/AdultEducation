package com.project.adult.DTO;

public class UserDTO {
    private String firstName;
    private String lastName;
    private String email;
    private Long programmeId;
    private String programmeName;
    private String token;
    private String role;
    public UserDTO(String firstName, String lastName, String email,
                   Long programmeId, String programmeName, String token,String role) {
        this.firstName     = firstName;
        this.lastName      = lastName;
        this.email         = email;
        this.programmeId   = programmeId;
        this.programmeName = programmeName;
        this.token         = token;
        this.role         = role;
    }

    public String getFirstName()     { return firstName; }
    public String getLastName()      { return lastName; }
    public String getEmail()         { return email; }
    public Long getProgrammeId()     { return programmeId; }
    public String getProgrammeName() { return programmeName; }
    public String getToken()         { return token; }
    public String getRole(){return role;}
}