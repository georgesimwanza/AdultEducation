package com.project.adult.DTO;

public class UserDTO {
    private String firstName;
    private String lastName;
    private String email;
    private Long programmeId;      // ← just the ID
    private String programmeName;  // ← just the name

    public UserDTO(String firstName, String lastName, String email,
                   Long programmeId, String programmeName) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.programmeId = programmeId;
        this.programmeName = programmeName;
    }

    // Getters
    public String getFirstName()    { return firstName; }
    public String getLastName()     { return lastName; }
    public String getEmail()        { return email; }
    public Long getProgrammeId()    { return programmeId; }
    public String getProgrammeName(){ return programmeName; }
}
