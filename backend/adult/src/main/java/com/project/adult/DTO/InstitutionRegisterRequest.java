package com.project.adult.DTO;

import lombok.Data;

@Data
public class InstitutionRegisterRequest {
    private String name;
    private String email;
    private String location;
    private String password;   // becomes the ADMIN user's password
}