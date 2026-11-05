package com.project.adult.Service;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Model.ActivityEvent;
import com.project.adult.Model.Course;
import com.project.adult.Model.Enrollment;
import com.project.adult.Model.User;
import com.project.adult.Model.UserContentProgress;
import com.project.adult.Repository.*;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Course enrollment. Learners are enrolled in their programme's courses
 * when their account is created, and can enroll in (or drop) any other
 * active course themselves.
 */
@Service
public class EnrollmentService {

    private final EnrollmentRepository enrollmentRepository;
    private final CourseRepository courseRepository;
    private final subjectRepository subjectRepository;
    private final ContentRepository contentRepository;
    private final ContentViewRepository contentViewRepository;
    private final UserContentProgressRepository progressRepository;
    private final ActivityService activityService;

    public EnrollmentService(EnrollmentRepository enrollmentRepository,
                             CourseRepository courseRepository,
                             subjectRepository subjectRepository,
                             ContentRepository contentRepository,
                             ContentViewRepository contentViewRepository,
                             UserContentProgressRepository progressRepository,
                             ActivityService activityService) {
        this.enrollmentRepository = enrollmentRepository;
        this.courseRepository = courseRepository;
        this.subjectRepository = subjectRepository;
        this.contentRepository = contentRepository;
        this.contentViewRepository = contentViewRepository;
        this.progressRepository = progressRepository;
        this.activityService = activityService;
    }

    /** Catalogue of active courses, flagged with whether the learner is enrolled. */
    public List<CourseSummary> catalogue(User learner) {
        Map<Long, Enrollment> mine = enrollmentRepository.findByUserWithCourse(learner.getId()).stream()
                .filter(e -> e.getStatus() != Enrollment.Status.DROPPED)
                .collect(Collectors.toMap(e -> e.getCourse().getId(), Function.identity(), (a, b) -> a));
        Map<Long, Short> progress = progressRepository.findByUserWithCourse(learner.getId()).stream()
                .collect(Collectors.toMap(p -> p.getCourse().getId(), UserContentProgress::getProgressPercentage, (a, b) -> a));
        return courseRepository.findAll().stream()
                .filter(c -> !Boolean.FALSE.equals(c.getIsActive()))
                .map(c -> new CourseSummary(c.getId(), c.getCourseCode(), c.getName(), c.getDescription(),
                        c.getCategory(), c.getLevel(), c.getCredits(), c.getIsActive(),
                        contentRepository.countByCourse_Id(c.getId()),
                        mine.containsKey(c.getId()),
                        progress.getOrDefault(c.getId(), (short) 0)))
                .toList();
    }

    @Transactional
    public EnrollmentDto enroll(User learner, Long courseId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Course not found"));
        if (Boolean.FALSE.equals(course.getIsActive())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This course is no longer open");
        }
        Enrollment e = ensureEnrolled(learner, course);
        activityService.record(learner.getId(), ActivityEvent.Type.ENROLL, courseId, "Enrolled in " + course.getName());
        return toDto(e);
    }

    @Transactional
    public void drop(User learner, Long courseId) {
        Enrollment e = enrollmentRepository.findByUser_IdAndCourse_Id(learner.getId(), courseId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "You are not enrolled in this course"));
        e.setStatus(Enrollment.Status.DROPPED);
        enrollmentRepository.save(e);
    }

    /** Enrolls (or re-activates) without logging; used by lesson views and sign-up. */
    @Transactional
    public Enrollment ensureEnrolled(User learner, Course course) {
        Enrollment e = enrollmentRepository.findByUser_IdAndCourse_Id(learner.getId(), course.getId())
                .orElseGet(() -> {
                    Enrollment n = new Enrollment();
                    n.setUser(learner);
                    n.setCourse(course);
                    return n;
                });
        if (e.getId() == null || e.getStatus() == Enrollment.Status.DROPPED) {
            e.setStatus(Enrollment.Status.ACTIVE);
            e.setEnrolledAt(LocalDateTime.now());
            e = enrollmentRepository.save(e);
        }
        return e;
    }

    @Transactional
    public void enrollInProgrammeCourses(User learner) {
        if (learner.getSelectedProgramme() == null) return;
        for (Course c : subjectRepository.findCoursesByProgrammeId(learner.getSelectedProgramme().getId())) {
            if (enrollmentRepository.findByUser_IdAndCourse_Id(learner.getId(), c.getId()).isEmpty()) {
                ensureEnrolled(learner, c);
            }
        }
    }

    /** The learner's course history: every enrollment with its progress. */
    public List<EnrollmentDto> myCourses(User learner) {
        return enrollmentRepository.findByUserWithCourse(learner.getId()).stream()
                .map(this::toDto)
                .toList();
    }

    public List<RosterEntry> roster(User staff, Long courseId) {
        return enrollmentRepository.findActiveByCourseWithUser(courseId).stream()
                .filter(e -> sameInstitution(staff, e.getUser()))
                .map(e -> new RosterEntry(e.getUser().getId(), ProfileService.fullName(e.getUser()),
                        e.getUser().getEmail(), e.getStatus().name(),
                        progressFor(e.getUser().getId(), courseId), e.getEnrolledAt()))
                .toList();
    }

    static boolean sameInstitution(User staff, User other) {
        Long own = CurrentUserService.institutionId(staff);
        return own == null || own.equals(CurrentUserService.institutionId(other));
    }

    int progressFor(Long userId, Long courseId) {
        return progressRepository.findByUser_IdAndCourse_Id(userId, courseId)
                .map(p -> (int) p.getProgressPercentage())
                .orElse(0);
    }

    EnrollmentDto toDto(Enrollment e) {
        Course c = e.getCourse();
        Long userId = e.getUser().getId();
        long total = contentRepository.countByCourse_Id(c.getId());
        long viewed = contentViewRepository.countByUser_IdAndCourseId(userId, c.getId());
        var progress = progressRepository.findByUser_IdAndCourse_Id(userId, c.getId());
        return new EnrollmentDto(e.getId(), c.getId(), c.getCourseCode(), c.getName(), e.getStatus().name(),
                e.getEnrolledAt(), e.getCompletedAt(),
                progress.map(p -> (int) p.getProgressPercentage()).orElse(0),
                viewed, total,
                progress.map(UserContentProgress::getLastAccessed).orElse(null));
    }
}
