package com.project.adult.Service;

import com.project.adult.Model.User;
import com.project.adult.Repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Resolves the signed-in user from the JWT principal. Endpoints always take
 * "who am I" from here, never from the request body, so a user can only act
 * as themselves.
 */
@Service
public class CurrentUserService {

    private final UserRepository userRepository;

    public CurrentUserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User require() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Not signed in");
        }
        return userRepository.findByEmailIgnoreCase(auth.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
    }

    public static boolean isStaff(User user) {
        return user.getRole() == User.Role.ADMIN
                || user.getRole() == User.Role.INSTRUCTOR
                || user.getRole() == User.Role.INSTITUTION;
    }

    /** Staff may only act on records belonging to their own institution. */
    public static void requireSameInstitution(User staff, Long institutionId) {
        Long own = staff.getInstitution() != null ? staff.getInstitution().getId() : null;
        if (own != null && institutionId != null && !own.equals(institutionId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "That record belongs to another institution");
        }
    }

    public static Long institutionId(User user) {
        return user.getInstitution() != null ? user.getInstitution().getId() : null;
    }
}
