package com.project.adult.Service;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Model.Programme;
import com.project.adult.Model.User;
import com.project.adult.Repository.ProgrammeRepository;
import com.project.adult.Repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.Comparator;
import java.util.List;
import java.util.Set;

/**
 * Learner profiles (personal details, education level) and the admin's
 * account management: create staff/learner accounts, change roles,
 * activate and deactivate accounts.
 */
@Service
public class ProfileService {

    static final Set<String> EDUCATION_LEVELS = Set.of(
            "No formal schooling", "Primary", "Junior secondary", "Senior secondary",
            "Certificate", "Diploma", "Degree", "Postgraduate");

    private final UserRepository userRepository;
    private final ProgrammeRepository programmeRepository;
    private final PasswordEncoder passwordEncoder;
    private final EnrollmentService enrollmentService;

    public ProfileService(UserRepository userRepository,
                          ProgrammeRepository programmeRepository,
                          PasswordEncoder passwordEncoder,
                          EnrollmentService enrollmentService) {
        this.userRepository = userRepository;
        this.programmeRepository = programmeRepository;
        this.passwordEncoder = passwordEncoder;
        this.enrollmentService = enrollmentService;
    }

    public static ProfileDto toDto(User u) {
        return new ProfileDto(
                u.getId(), u.getFirstName(), u.getLastName(), u.getEmail(),
                u.getRole() != null ? u.getRole().name() : null,
                u.getPhoneNumber(), u.getDateOfBirth(), u.getGender(), u.getAddress(),
                u.getEducationLevel(), u.getOccupation(),
                u.getInstitution() != null ? u.getInstitution().getId() : null,
                u.getInstitution() != null ? u.getInstitution().getName() : null,
                u.getSelectedProgramme() != null ? u.getSelectedProgramme().getId() : null,
                u.getSelectedProgramme() != null ? u.getSelectedProgramme().getName() : null,
                u.getIsActive(), u.getCreatedAt(), u.getLastLoginAt());
    }

    public static String fullName(User u) {
        return (u.getFirstName() + " " + u.getLastName()).trim();
    }

    @Transactional
    public ProfileDto updateProfile(User user, ProfileUpdateRequest req) {
        if (req.firstName() != null) user.setFirstName(requireText(req.firstName(), "First name", 100));
        if (req.lastName() != null) user.setLastName(requireText(req.lastName(), "Last name", 100));
        if (req.phoneNumber() != null) user.setPhoneNumber(optionalText(req.phoneNumber(), 30));
        if (req.dateOfBirth() != null) user.setDateOfBirth(optionalDate(req.dateOfBirth()));
        if (req.gender() != null) user.setGender(optionalText(req.gender(), 20));
        if (req.address() != null) user.setAddress(optionalText(req.address(), 300));
        if (req.occupation() != null) user.setOccupation(optionalText(req.occupation(), 150));
        if (req.educationLevel() != null) {
            String level = optionalText(req.educationLevel(), 100);
            if (level != null && !EDUCATION_LEVELS.contains(level)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Education level must be one of: " + String.join(", ", EDUCATION_LEVELS));
            }
            user.setEducationLevel(level);
        }
        return toDto(userRepository.save(user));
    }

    // ── Admin account management ─────────────────────────────────────

    public List<ProfileDto> listUsers(User admin) {
        Long institutionId = CurrentUserService.institutionId(admin);
        List<User> users = institutionId != null
                ? userRepository.findByInstitutionId(institutionId)
                : userRepository.findAll();
        return users.stream()
                .sorted(Comparator.comparing(User::getRole).thenComparing(User::getFirstName))
                .map(ProfileService::toDto)
                .toList();
    }

    @Transactional
    public ProfileDto createUser(User admin, CreateUserRequest req) {
        String email = requireText(req.email(), "Email", 255).toLowerCase();
        if (!email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Enter a valid email address");
        }
        if (userRepository.findByEmailIgnoreCase(email).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "An account with that email already exists");
        }
        validatePassword(req.password());

        User user = new User();
        user.setFirstName(requireText(req.firstName(), "First name", 100));
        user.setLastName(requireText(req.lastName(), "Last name", 100));
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(req.password()));
        user.setRole(parseAssignableRole(req.role()));
        user.setInstitution(admin.getInstitution());
        user.setEducationLevel(optionalText(req.educationLevel(), 100));
        if (req.programmeId() != null) {
            Programme programme = programmeRepository.findById(req.programmeId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Programme not found"));
            user.setSelectedProgramme(programme);
        }
        User saved = userRepository.save(user);
        if (saved.getRole() == User.Role.USER) {
            enrollmentService.enrollInProgrammeCourses(saved);
        }
        return toDto(saved);
    }

    @Transactional
    public ProfileDto changeRole(User admin, Long userId, String role) {
        User user = managedUser(admin, userId);
        if (user.getId().equals(admin.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "You can't change your own role");
        }
        user.setRole(parseAssignableRole(role));
        return toDto(userRepository.save(user));
    }

    @Transactional
    public ProfileDto setActive(User admin, Long userId, boolean active) {
        User user = managedUser(admin, userId);
        if (user.getId().equals(admin.getId()) && !active) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "You can't deactivate your own account");
        }
        user.setIsActive(active);
        return toDto(userRepository.save(user));
    }

    private User managedUser(User admin, Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        CurrentUserService.requireSameInstitution(admin, CurrentUserService.institutionId(user));
        return user;
    }

    /** Admins can assign learner, instructor or admin; INSTITUTION is only created at sign-up. */
    private static User.Role parseAssignableRole(String role) {
        if (role == null || role.isBlank()) return User.Role.USER;
        return switch (role.trim().toUpperCase()) {
            case "USER", "LEARNER" -> User.Role.USER;
            case "INSTRUCTOR" -> User.Role.INSTRUCTOR;
            case "ADMIN" -> User.Role.ADMIN;
            default -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Role must be LEARNER, INSTRUCTOR or ADMIN");
        };
    }

    static void validatePassword(String password) {
        if (password == null || password.length() < 8) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Password must be at least 8 characters");
        }
    }

    private static String requireText(String value, String field, int max) {
        if (value == null || value.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, field + " is required");
        }
        String trimmed = value.trim();
        if (trimmed.length() > max) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, field + " is too long");
        }
        return trimmed;
    }

    private static String optionalText(String value, int max) {
        if (value == null || value.isBlank()) return null;
        String trimmed = value.trim();
        return trimmed.length() > max ? trimmed.substring(0, max) : trimmed;
    }

    private static String optionalDate(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return java.time.LocalDate.parse(value.trim()).toString();
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Date of birth must be YYYY-MM-DD");
        }
    }
}
