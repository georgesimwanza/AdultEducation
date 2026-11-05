package com.project.adult.Service;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Model.Attendance;
import com.project.adult.Model.Course;
import com.project.adult.Model.Enrollment;
import com.project.adult.Model.User;
import com.project.adult.Repository.AttendanceRepository;
import com.project.adult.Repository.CourseRepository;
import com.project.adult.Repository.EnrollmentRepository;
import com.project.adult.Repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Attendance registers: instructors mark a course for a day; learners see their own record. */
@Service
public class AttendanceService {

    private final AttendanceRepository attendanceRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final CourseRepository courseRepository;
    private final UserRepository userRepository;

    public AttendanceService(AttendanceRepository attendanceRepository,
                             EnrollmentRepository enrollmentRepository,
                             CourseRepository courseRepository,
                             UserRepository userRepository) {
        this.attendanceRepository = attendanceRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.courseRepository = courseRepository;
        this.userRepository = userRepository;
    }

    /** The register for one course and day: every enrolled learner, with any status already recorded. */
    public List<AttendanceSheetEntry> sheet(User staff, Long courseId, LocalDate date) {
        Map<Long, Attendance> recorded = attendanceRepository.findByCourseAndDate(courseId, date).stream()
                .collect(Collectors.toMap(a -> a.getLearner().getId(), Function.identity(), (a, b) -> a));
        return enrollmentRepository.findActiveByCourseWithUser(courseId).stream()
                .map(Enrollment::getUser)
                .filter(u -> EnrollmentService.sameInstitution(staff, u))
                .map(u -> {
                    Attendance a = recorded.get(u.getId());
                    return new AttendanceSheetEntry(u.getId(), ProfileService.fullName(u),
                            a != null ? a.getStatus().name() : null,
                            a != null ? a.getSource() : null);
                })
                .toList();
    }

    @Transactional
    public List<AttendanceSheetEntry> mark(User staff, AttendanceMarkRequest req) {
        if (req.courseId() == null || req.entries() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Course and entries are required");
        }
        LocalDate date = req.date() != null ? req.date() : LocalDate.now();
        if (date.isAfter(LocalDate.now())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Attendance can't be recorded for a future date");
        }
        Course course = courseRepository.findById(req.courseId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Course not found"));
        for (AttendanceMark m : req.entries()) {
            if (m.learnerId() == null || m.status() == null) continue;
            User learner = userRepository.findById(m.learnerId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Learner not found"));
            if (!EnrollmentService.sameInstitution(staff, learner)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Learner belongs to another institution");
            }
            Attendance a = attendanceRepository
                    .findByCourse_IdAndLearner_IdAndSessionDate(course.getId(), learner.getId(), date)
                    .orElseGet(Attendance::new);
            a.setCourse(course);
            a.setLearner(learner);
            a.setSessionDate(date);
            a.setStatus(parseStatus(m.status()));
            a.setSource("MANUAL");
            a.setRecordedBy(staff);
            a.setRecordedAt(LocalDateTime.now());
            attendanceRepository.save(a);
        }
        return sheet(staff, course.getId(), date);
    }

    public List<AttendanceRecordDto> forLearner(Long learnerId) {
        return attendanceRepository.findByLearnerWithCourse(learnerId).stream()
                .map(a -> new AttendanceRecordDto(a.getId(), a.getCourse().getId(), a.getCourse().getName(),
                        a.getSessionDate(), a.getStatus().name(), a.getSource()))
                .toList();
    }

    /** Percentage of recorded sessions attended (present, late or excused); null when nothing is recorded. */
    public static Integer rate(Collection<Attendance> records) {
        if (records.isEmpty()) return null;
        long attended = records.stream().filter(a -> a.getStatus() != Attendance.Status.ABSENT).count();
        return (int) Math.round(attended * 100.0 / records.size());
    }

    public static Integer rateFromDtos(Collection<AttendanceRecordDto> records) {
        if (records.isEmpty()) return null;
        long attended = records.stream().filter(a -> !"ABSENT".equals(a.status())).count();
        return (int) Math.round(attended * 100.0 / records.size());
    }

    private static Attendance.Status parseStatus(String status) {
        try {
            return Attendance.Status.valueOf(status.trim().toUpperCase());
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Status must be PRESENT, ABSENT, LATE or EXCUSED");
        }
    }
}
