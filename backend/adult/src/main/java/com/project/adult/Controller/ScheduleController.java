package com.project.adult.Controller;

import com.project.adult.DTO.ScheduleDTO;
import com.project.adult.Model.Schedule;
import com.project.adult.Service.ScheduleService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/schedules")
@CrossOrigin(origins = "*") // 👈 allows requests from Flutter
public class ScheduleController {

    private final ScheduleService scheduleService;

    public ScheduleController(ScheduleService scheduleService) {
        this.scheduleService = scheduleService;
    }


    @PostMapping
    public ResponseEntity<ScheduleDTO> addSchedule(@RequestBody Schedule schedule) {
        ScheduleDTO saved = scheduleService.addSchedule(schedule);
        return ResponseEntity.ok(saved);
    }

    @GetMapping
    public ResponseEntity<List<ScheduleDTO>> getSchedules(@RequestParam String email) {
        List<ScheduleDTO> schedules = scheduleService.getSchedulesByEmail(email);
        return ResponseEntity.ok(schedules);
    }


    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSchedule(@PathVariable Long id) {
        scheduleService.deleteSchedule(id);
        return ResponseEntity.noContent().build();
    }
}