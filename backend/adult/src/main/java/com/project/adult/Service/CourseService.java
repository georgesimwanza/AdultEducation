package com.project.adult.Service;

import com.project.adult.Model.Course;
import com.project.adult.Repository.CourseRepository;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service layer for managing {@link Course} entities.
 * <p>
 * Provides basic creation and retrieval operations for courses.
 */
@Service
public class CourseService {
    private final CourseRepository courseRepository;

    /**
     * Constructs the service with its required repository.
     *
     * @param courseRepository repository for persisting and querying courses
     */
    public CourseService(CourseRepository courseRepository) {
        this.courseRepository = courseRepository;
    }

    /**
     * Creates and persists a new course.
     *
     * @param course the course to create
     * @return the saved course, including its generated id
     */
    public Course addCourse(Course course)
    {
        return courseRepository.save(course);
    }

    /**
     * Retrieves a single course by its identifier.
     *
     * @param Id the course id
     * @return the matching course
     * @throws RuntimeException if no course exists with the given id
     */
    public Course getCourse(Long Id){
        return courseRepository.findById(Id).orElseThrow(()-> new RuntimeException("course not found"));
    }

    /**
     * Retrieves all courses in the system.
     *
     * @return a list of all courses
     */
    public List<Course> getAllCourses() {
        return courseRepository.findAll();
    }
}