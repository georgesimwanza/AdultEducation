package com.project.adult.Service;

import com.project.adult.DTO.LearningDtos.CourseRequest;
import com.project.adult.DTO.LearningDtos.CourseSummary;
import com.project.adult.Model.*;
import com.project.adult.Repository.*;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

/**
 * Service layer for managing {@link Course} entities.
 * <p>
 * Provides creation, update, archiving and retrieval of courses. Archiving
 * (isActive = false) is used instead of deleting, so learners' progress,
 * grades and attendance for the course are kept.
 */
@Service
public class CourseService {
    private final CourseRepository courseRepository;
    private final ProgrammeRepository programmeRepository;
    private final ProgrammeCourseRepository programmeCourseRepository;
    private final ContentRepository contentRepository;
    private final UserRepository userRepository;
    private final EnrollmentService enrollmentService;

    /**
     * Constructs the service with its required repositories.
     *
     * @param courseRepository repository for persisting and querying courses
     */
    public CourseService(CourseRepository courseRepository,
                         ProgrammeRepository programmeRepository,
                         ProgrammeCourseRepository programmeCourseRepository,
                         ContentRepository contentRepository,
                         UserRepository userRepository,
                         EnrollmentService enrollmentService) {
        this.courseRepository = courseRepository;
        this.programmeRepository = programmeRepository;
        this.programmeCourseRepository = programmeCourseRepository;
        this.contentRepository = contentRepository;
        this.userRepository = userRepository;
        this.enrollmentService = enrollmentService;
    }

    /**
     * Creates and persists a new course.
     *
     * @param course the course to create
     * @return the saved course, including its generated id
     */
    public Course addCourse(Course course)
    {
        if (course.getUuid() == null) course.setUuid(UUID.randomUUID());
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

    /** All courses, including archived ones, for the course management screen. */
    public List<CourseSummary> manageList() {
        return courseRepository.findAll().stream()
                .map(c -> new CourseSummary(c.getId(), c.getCourseCode(), c.getName(), c.getDescription(),
                        c.getCategory(), c.getLevel(), c.getCredits(), c.getIsActive(),
                        contentRepository.countByCourse_Id(c.getId()), false, 0))
                .toList();
    }

    /**
     * Creates a course and, if a programme is given, adds it to that
     * programme and enrolls the programme's learners in it.
     */
    @Transactional
    public CourseSummary create(CourseRequest req) {
        Course course = new Course();
        course.setUuid(UUID.randomUUID());
        apply(course, req, true);
        course = courseRepository.save(course);

        if (req.programmeId() != null) {
            Programme programme = programmeRepository.findById(req.programmeId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Programme not found"));
            ProgrammeCourse link = new ProgrammeCourse();
            link.setId(new ProgrammeCourseId(programme.getId(), course.getId()));
            link.setProgramme(programme);
            link.setCourse(course);
            link.setIsRequired(Boolean.TRUE.equals(req.isMandatory()));
            programmeCourseRepository.save(link);
            for (User learner : userRepository.findBySelectedProgramme_IdAndRole(programme.getId(), User.Role.USER)) {
                enrollmentService.ensureEnrolled(learner, course);
            }
        }
        return summary(course);
    }

    @Transactional
    public CourseSummary update(Long id, CourseRequest req) {
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Course not found"));
        apply(course, req, false);
        return summary(courseRepository.save(course));
    }

    /** Archive or re-open a course. Archived courses disappear from the learner catalogue. */
    @Transactional
    public CourseSummary setActive(Long id, boolean active) {
        Course course = courseRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Course not found"));
        course.setIsActive(active);
        return summary(courseRepository.save(course));
    }

    private void apply(Course course, CourseRequest req, boolean creating) {
        if (creating || req.courseCode() != null) {
            if (req.courseCode() == null || req.courseCode().isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Course code is required");
            }
            String code = req.courseCode().trim().toUpperCase();
            if (!code.equalsIgnoreCase(course.getCourseCode()) && courseRepository.existsByCourseCodeIgnoreCase(code)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Course code " + code + " is already used");
            }
            course.setCourseCode(code);
        }
        if (creating || req.name() != null) {
            if (req.name() == null || req.name().isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Course name is required");
            }
            course.setName(req.name().trim());
        }
        if (req.description() != null) course.setDescription(req.description().trim());
        if (req.category() != null) course.setCategory(req.category().trim());
        if (req.level() != null) course.setLevel(req.level().trim());
        if (req.credits() != null) course.setCredits(Math.max(0, req.credits()));
        if (req.hoursPerWeek() != null) course.setHoursPerWeek(Math.max(0, req.hoursPerWeek()));
        if (req.isMandatory() != null) course.setIsMandatory(req.isMandatory());
    }

    private CourseSummary summary(Course c) {
        return new CourseSummary(c.getId(), c.getCourseCode(), c.getName(), c.getDescription(),
                c.getCategory(), c.getLevel(), c.getCredits(), c.getIsActive(),
                contentRepository.countByCourse_Id(c.getId()), false, 0);
    }
}
