package com.project.adult.Controller;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Service.CurrentUserService;
import com.project.adult.Service.ProfileService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * The signed-in user's own profile (personal details and education level),
 * and the admin's account management under /api/admin/users.
 */
@RestController
public class ProfileController {

    private static final String ADMIN = "hasAnyRole('ADMIN','INSTITUTION')";

    private final ProfileService profileService;
    private final CurrentUserService currentUser;

    public ProfileController(ProfileService profileService, CurrentUserService currentUser) {
        this.profileService = profileService;
        this.currentUser = currentUser;
    }

    @GetMapping("/api/profile")
    public ProfileDto me() {
        return ProfileService.toDto(currentUser.require());
    }

    @PutMapping("/api/profile")
    public ProfileDto update(@RequestBody ProfileUpdateRequest request) {
        return profileService.updateProfile(currentUser.require(), request);
    }

    @GetMapping("/api/profile/education-levels")
    public List<String> educationLevels() {
        return List.of("No formal schooling", "Primary", "Junior secondary", "Senior secondary",
                "Certificate", "Diploma", "Degree", "Postgraduate");
    }

    // ── Admin: manage accounts ───────────────────────────────────────

    @PreAuthorize(ADMIN)
    @GetMapping("/api/admin/users")
    public List<ProfileDto> listUsers() {
        return profileService.listUsers(currentUser.require());
    }

    @PreAuthorize(ADMIN)
    @PostMapping("/api/admin/users")
    public ProfileDto createUser(@RequestBody CreateUserRequest request) {
        return profileService.createUser(currentUser.require(), request);
    }

    @PreAuthorize(ADMIN)
    @PatchMapping("/api/admin/users/{id}/role")
    public ProfileDto changeRole(@PathVariable Long id, @RequestBody RoleUpdateRequest request) {
        return profileService.changeRole(currentUser.require(), id, request.role());
    }

    @PreAuthorize(ADMIN)
    @PatchMapping("/api/admin/users/{id}/status")
    public ProfileDto setStatus(@PathVariable Long id, @RequestBody StatusUpdateRequest request) {
        return profileService.setActive(currentUser.require(), id, !Boolean.FALSE.equals(request.active()));
    }
}
