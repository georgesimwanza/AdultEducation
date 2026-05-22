package com.project.adult.Controller;


import com.project.adult.Model.Course;
import com.project.adult.Service.CourseService;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@CrossOrigin("http://localhost:5173")
@RequestMapping("/api/course")
public class CourseController {
    private final CourseService courseService;
    public CourseController(CourseService courseService){
        this.courseService=courseService;
    }

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


}
