package com.project.adult.Controller;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Service.CurrentUserService;
import com.project.adult.Service.ReportService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Progress reports, performance and completion reports, participation monitoring and dashboards. */
@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private static final String STAFF = "hasAnyRole('ADMIN','INSTRUCTOR','INSTITUTION')";

    private final ReportService reportService;
    private final CurrentUserService currentUser;

    public ReportController(ReportService reportService, CurrentUserService currentUser) {
        this.reportService = reportService;
        this.currentUser = currentUser;
    }

    @GetMapping("/me")
    public LearnerReport myReport() {
        var me = currentUser.require();
        return reportService.learnerReport(me, me.getId());
    }

    @GetMapping("/dashboard/learner")
    public LearnerDashboard learnerDashboard() {
        return reportService.learnerDashboard(currentUser.require());
    }

    @PreAuthorize(STAFF)
    @GetMapping("/learner/{learnerId}")
    public LearnerReport learnerReport(@PathVariable Long learnerId) {
        return reportService.learnerReport(currentUser.require(), learnerId);
    }

    @PreAuthorize(STAFF)
    @GetMapping("/courses")
    public List<CourseStats> courses() {
        return reportService.courseStats(currentUser.require());
    }

    @PreAuthorize(STAFF)
    @GetMapping("/participation")
    public List<ParticipationLine> participation() {
        return reportService.participation(currentUser.require());
    }

    @PreAuthorize(STAFF)
    @GetMapping("/dashboard/admin")
    public AdminDashboard adminDashboard() {
        return reportService.adminDashboard(currentUser.require());
    }

    @PreAuthorize(STAFF)
    @GetMapping(value = "/courses.csv", produces = "text/csv")
    public ResponseEntity<String> coursesCsv() {
        return csv("course-report.csv", reportService.courseStatsCsv(currentUser.require()));
    }

    @PreAuthorize(STAFF)
    @GetMapping(value = "/participation.csv", produces = "text/csv")
    public ResponseEntity<String> participationCsv() {
        return csv("participation-report.csv", reportService.participationCsv(currentUser.require()));
    }

    private static ResponseEntity<String> csv(String filename, String body) {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(body);
    }
}
