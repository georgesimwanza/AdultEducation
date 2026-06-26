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
import com.project.adult.Security.UserPrincipal;
import jakarta.transaction.Transactional;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import com.project.adult.Model.User.Role;
import java.util.List;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final ProgrammeRepository programmeRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;
    private final InstitutionRepository institutionRepository;

    public UserService(UserRepository userRepository,
                       ProgrammeRepository programmeRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtils jwtUtils,
                       InstitutionRepository institutionRepository) {
        this.userRepository        = userRepository;
        this.programmeRepository   = programmeRepository;
        this.passwordEncoder       = passwordEncoder;
        this.jwtUtils              = jwtUtils;
        this.institutionRepository = institutionRepository;
    }

    @Transactional
    public User CreateUser(RegisterRequest request) {
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

        return userRepository.save(user);
    }

    public User getUser(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    public UserDTO login(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw new RuntimeException("Invalid password");
        }

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

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }
}