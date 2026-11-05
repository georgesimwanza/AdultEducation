package com.project.adult.Controller;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Service.AttendanceService;
import com.project.adult.Service.CurrentUserService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/** Attendance registers for instructors and attendance history for learners. */
@RestController
@RequestMapping("/api/attendance")
public class AttendanceController {

    private static final String STAFF = "hasAnyRole('ADMIN','INSTRUCTOR','INSTITUTION')";

    private final AttendanceService attendanceService;
    private final CurrentUserService currentUser;

    public AttendanceController(AttendanceService attendanceService, CurrentUserService currentUser) {
        this.attendanceService = attendanceService;
        this.currentUser = currentUser;
    }

    @GetMapping("/me")
    public List<AttendanceRecordDto> mine() {
        return attendanceService.forLearner(currentUser.require().getId());
    }

    @PreAuthorize(STAFF)
    @GetMapping("/sheet")
    public List<AttendanceSheetEntry> sheet(@RequestParam Long courseId,
                                            @RequestParam(required = false)
                                            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return attendanceService.sheet(currentUser.require(), courseId, date != null ? date : LocalDate.now());
    }

    @PreAuthorize(STAFF)
    @PostMapping("/mark")
    public List<AttendanceSheetEntry> mark(@RequestBody AttendanceMarkRequest request) {
        return attendanceService.mark(currentUser.require(), request);
    }
}
