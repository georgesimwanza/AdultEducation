package com.project.adult.Model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Table(name = "institutions")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Institution {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String location;

    @OneToMany(mappedBy = "institution")
    @JsonIgnore
    @JsonManagedReference
    private List<User> users;

    @OneToMany(mappedBy = "institution")
    @JsonIgnoreProperties("institution")
    private List<Content> contents;

    @OneToMany(mappedBy = "institution")
    @JsonIgnoreProperties({"institution", "hibernateLazyInitializer", "handler"})
    private List<Quiz> quiz;
}