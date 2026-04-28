package com.project.adult.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;


@Data
@AllArgsConstructor
@NoArgsConstructor
public class ScheduleDTO {

    private Long id;
    private String title;
    private String userEmail;
    private LocalDate date;
    private LocalTime startTime;
    private LocalTime endTime;

}