package com.project.adult.Service;

import com.project.adult.DTO.RegisterRequest;
import com.project.adult.DTO.UserDTO;
import com.project.adult.Model.Institution;
import com.project.adult.Model.Programme;
import com.project.adult.Model.User;
import com.project.adult.Repository.InstitutionRepository;
import com.project.adult.Repository.ProgrammeRepository;
import com.project.adult.Repository.UserRepository;
import com.project.adult.Security.JwtUtils;
import com.project.adult.Security.LoginAttemptService;
import com.project.adult.Security.UserPrincipal;
import jakarta.transaction.Transactional;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import com.project.adult.Model.User.Role;
import java.util.List;

/**
 * Service layer for managing {@link User} entities.
 * <p>
 * Handles user registration, authentication (login), and lookups, including
 * institution- and role-scoped queries used by admin views.
 */
@Service
public class UserService {

    private final UserRepository userRepository;
    private final ProgrammeRepository programmeRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;
    private final InstitutionRepository institutionRepository;
    private final EnrollmentService enrollmentService;
    private final ActivityService activityService;
    private final LoginAttemptService loginAttemptService;

    /**
     * Constructs the service with its required repositories and security helpers.
     *
     * @param userRepository        repository for persisting and querying users
     * @param programmeRepository   repository for looking up a user's selected programme
     * @param passwordEncoder       encoder used to hash and verify user passwords
     * @param jwtUtils              utility used to generate auth tokens on login/registration
     * @param institutionRepository repository for looking up a user's institution
     */
    public UserService(UserRepository userRepository,
                       ProgrammeRepository programmeRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtils jwtUtils,
                       InstitutionRepository institutionRepository,
                       EnrollmentService enrollmentService,
                       ActivityService activityService,
                       LoginAttemptService loginAttemptService) {
        this.userRepository        = userRepository;
        this.programmeRepository   = programmeRepository;
        this.passwordEncoder       = passwordEncoder;
        this.jwtUtils              = jwtUtils;
        this.institutionRepository = institutionRepository;
        this.enrollmentService     = enrollmentService;
        this.activityService       = activityService;
        this.loginAttemptService   = loginAttemptService;
    }

    /**
     * Registers a new standard (USER role) account, optionally linking it to
     * an institution and/or a selected programme.
     *
     * @param request the registration payload, including name, email, password,
     *                and optional institution/programme ids
     * @return the saved user, including its generated id
     * @throws RuntimeException if a given institution or programme id does not exist
     */
    @Transactional
    public User CreateUser(RegisterRequest request) {
        if (request.getEmail() == null || request.getEmail().isBlank()) {
            throw new RuntimeException("Email is required");
        }
        if (userRepository.findByEmailIgnoreCase(request.getEmail().trim()).isPresent()) {
            throw new RuntimeException("An account with that email already exists");
        }
        if (request.getPasswordHash() == null || request.getPasswordHash().length() < 8) {
            throw new RuntimeException("Password must be at least 8 characters");
        }
        User user = new User();
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setEmail(request.getEmail());
        user.setRole(Role.USER);
        user.setPasswordHash(passwordEncoder.encode(request.getPasswordHash()));

        if (request.getInstitutionId() != null) {
            Institution institution = institutionRepository
                    .findById(request.getInstitutionId())
                    .orElseThrow(() -> new RuntimeException(
                            "Institution not found with id: " + request.getInstitutionId()
                    ));
            user.setInstitution(institution);
        }

        if (request.getSelectedProgramme() != null &&
                request.getSelectedProgramme().getId() != null) {
            Programme programme = programmeRepository
                    .findById(request.getSelectedProgramme().getId())
                    .orElseThrow(() -> new RuntimeException(
                            "Programme not found with id: " + request.getSelectedProgramme().getId()
                    ));
            user.setSelectedProgramme(programme);
        }

        User saved = userRepository.save(user);
        enrollmentService.enrollInProgrammeCourses(saved);
        return saved;
    }

    /**
     * Retrieves a single user by their identifier.
     *
     * @param id the user id
     * @return the matching user
     * @throws RuntimeException if no user exists with the given id
     */
    public User getUser(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    /**
     * Authenticates a user by email and password, returning their profile
     * and an auth token on success.
     *
     * @param email    the user's email address
     * @param password the plaintext password to verify against the stored hash
     * @return a {@link UserDTO} containing the user's profile and a generated auth token
     * @throws RuntimeException if no user exists with the given email, or if the password is invalid
     */
    public UserDTO login(String email, String password) {
        if (loginAttemptService.isBlocked(email)) {
            throw new RuntimeException("Too many failed attempts. Please wait 15 minutes and try again.");
        }
        // Same message for unknown email and wrong password, so the login
        // form can't be used to find out which emails have accounts.
        User user = userRepository.findByEmailIgnoreCase(email == null ? "" : email.trim())
                .orElse(null);
        if (user == null || password == null || !passwordEncoder.matches(password, user.getPasswordHash())) {
            loginAttemptService.recordFailure(email);
            throw new RuntimeException("Incorrect email or password");
        }
        if (Boolean.FALSE.equals(user.getIsActive())) {
            throw new RuntimeException("This account has been deactivated. Please contact your institution.");
        }
        loginAttemptService.recordSuccess(email);
        user.setLastLoginAt(java.time.LocalDateTime.now());
        userRepository.save(user);
        activityService.record(user.getId(), com.project.adult.Model.ActivityEvent.Type.LOGIN, null, null);

        String token = jwtUtils.generateToken(UserPrincipal.from(user));

        Long programmeId     = null;
        String programmeName = null;
        if (user.getSelectedProgramme() != null) {
            programmeId   = user.getSelectedProgramme().getId();
            programmeName = user.getSelectedProgramme().getName();
        }

        return new UserDTO(
                user.getFirstName(),
                user.getLastName(),
                user.getEmail(),
                programmeId,
                programmeName,
                token,
                user.getRole().name(),
                user.getInstitution() != null ? user.getInstitution().getId() : null,
                user.getInstitution() != null ? user.getInstitution().getName() : null
        );
    }

    /**
     * Retrieves all users in the system.
     *
     * @return a list of all users
     */
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    /**
     * Retrieves all users belonging to a specific institution.
     *
     * @param institution the id of the institution
     * @return a list of users belonging to the given institution
     * @throws RuntimeException if the underlying repository call fails
     */
    public List<User> getUserByInstitution(Long institution){
        try {
            return this.userRepository.findByInstitutionId(institution);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
    /*
     * this method counts all the user in the system
     * this method is for the admin
     * */
    /**
     * Counts all users in the system. Intended for admin-facing dashboards.
     *
     * @return the total number of users
     */
    public Long countUsers(){
        return this.userRepository.count();
    }

    /*
     * this method return a number of users that belong to an institution
     * @param institution
     * */

    /**
     * Counts the number of users belonging to a specific institution.
     *
     * @param institutionId the id of the institution
     * @return the number of users belonging to the given institution
     */
    public Long CountUsersByInstitution(long institutionId){
        return this.userRepository.countByInstitution_id(institutionId);
    }

    /**
     * Changes the password of an authenticated user after verifying their
     * current one. The caller identifies the user from the security context,
     * never from the request body, so users can only change their own password.
     *
     * @param email           the authenticated user's email (from the JWT principal)
     * @param currentPassword the user's current plaintext password
     * @param newPassword     the new plaintext password
     * @throws IllegalArgumentException if a field is missing, the current password is
     *                                  wrong, or the new password is too short / unchanged
     */
    @Transactional
    public void changePassword(String email, String currentPassword, String newPassword) {
        if (currentPassword == null || currentPassword.isBlank()
                || newPassword == null || newPassword.isBlank()) {
            throw new IllegalArgumentException("Current and new password are required");
        }
        if (newPassword.length() < 8) {
            throw new IllegalArgumentException("New password must be at least 8 characters");
        }

        User user = userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw new IllegalArgumentException("Current password is incorrect");
        }
        if (passwordEncoder.matches(newPassword, user.getPasswordHash())) {
            throw new IllegalArgumentException("New password must be different from the current one");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }
}