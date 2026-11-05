package com.project.adult.Controller;


import com.project.adult.DTO.LearningDtos.CourseRequest;
import com.project.adult.DTO.LearningDtos.CourseSummary;
import com.project.adult.DTO.LearningDtos.StatusUpdateRequest;
import com.project.adult.Model.Course;
import com.project.adult.Service.CourseService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@CrossOrigin("http://localhost:5173")
@RequestMapping("/api/course")
public class CourseController {
    private static final String STAFF = "hasAnyRole('ADMIN','INSTRUCTOR','INSTITUTION')";

    private final CourseService courseService;
    public CourseController(CourseService courseService){
        this.courseService=courseService;
    }

    @PreAuthorize(STAFF)
    @PostMapping("/addCourse")
    public Course addCourse(@RequestBody Course course){
        return  courseService.addCourse(course);
    }
    @GetMapping("/getAllCourses")
    public List<Course> getAllCourses() {
        return courseService.getAllCourses();
    }

    // Fix the existing getCourse path variable
    @GetMapping("/getCourse/{Id}")
    public Course getCourse(@PathVariable Long Id) {
        return courseService.getCourse(Id);
    }

    // ── Course management (staff) ────────────────────────────────────

    @PreAuthorize(STAFF)
    @GetMapping("/manage")
    public List<CourseSummary> manageList() {
        return courseService.manageList();
    }

    @PreAuthorize(STAFF)
    @PostMapping("/manage")
    public CourseSummary create(@RequestBody CourseRequest request) {
        return courseService.create(request);
    }

    @PreAuthorize(STAFF)
    @PutMapping("/manage/{id}")
    public CourseSummary update(@PathVariable Long id, @RequestBody CourseRequest request) {
        return courseService.update(id, request);
    }

    /** Archive (active=false) or re-open a course. */
    @PreAuthorize(STAFF)
    @PatchMapping("/manage/{id}/status")
    public CourseSummary setStatus(@PathVariable Long id, @RequestBody StatusUpdateRequest request) {
        return courseService.setActive(id, !Boolean.FALSE.equals(request.active()));
    }
}
