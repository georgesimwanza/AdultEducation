package com.project.adult.Service;

import com.project.adult.Model.Course;
import com.project.adult.Repository.CourseRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CourseService {
    private final CourseRepository courseRepository;

    public CourseService(CourseRepository courseRepository) {
        this.courseRepository = courseRepository;
    }

    public Course addCourse(Course course)
    {
        return courseRepository.save(course);
    }
    public Course getCourse(String Id){
        return courseRepository.findById(Id).orElseThrow(()-> new RuntimeException("course not found"));
    }
    public List<Course> getAllCourses() {
        return courseRepository.findAll();
    }
}
