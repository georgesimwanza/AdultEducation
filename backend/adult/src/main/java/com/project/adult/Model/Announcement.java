package com.project.adult.Model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "Announcement")
public class Announcement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne
    @JoinColumn(name = "institution_id")
    @JsonIgnoreProperties({"contents","quiz","programmes", "students","announcements", "hibernateLazyInitializer", "handler"})
    private Institution institution;

    @ManyToOne
    @JoinColumn(name = "programme_id")
    @JsonIgnoreProperties({"institution", "students","announcements", "hibernateLazyInitializer", "handler"})
    private Programme programme;

    private String title;

    @Column(length = 5000)
    private String content;
}