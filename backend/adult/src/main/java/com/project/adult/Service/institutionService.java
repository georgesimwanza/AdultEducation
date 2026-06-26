package com.project.adult.Service;

import com.project.adult.DTO.InstitutionDto;
import com.project.adult.DTO.InstitutionRegisterRequest;
import com.project.adult.DTO.UserDTO;
import com.project.adult.Model.Institution;
import com.project.adult.Model.User;
import com.project.adult.Repository.InstitutionRepository;
import com.project.adult.Repository.UserRepository;
import com.project.adult.Security.JwtUtils;
import com.project.adult.Security.UserPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class institutionService {

    private final InstitutionRepository institutionRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;

    public institutionService(InstitutionRepository institutionRepository,
                              UserRepository userRepository,
                              PasswordEncoder passwordEncoder,
                              JwtUtils jwtUtils) {
        this.institutionRepository = institutionRepository;
        this.userRepository        = userRepository;
        this.passwordEncoder       = passwordEncoder;
        this.jwtUtils              = jwtUtils;
    }

    @Transactional
    public UserDTO registerWithAdmin(InstitutionRegisterRequest request) {
        if (institutionRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Institution email already registered");
        }

        // 1. Save institution
        Institution institution = new Institution();
        institution.setName(request.getName());
        institution.setEmail(request.getEmail());
        institution.setLocation(request.getLocation());
        Institution saved = institutionRepository.save(institution);

        // 2. Create ADMIN user with same email
        User admin = new User();
        admin.setFirstName(request.getName()); // institution name as firstName
        admin.setLastName("Admin");
        admin.setEmail(request.getEmail());
        admin.setRole(User.Role.ADMIN);
        admin.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        admin.setInstitution(saved);
        User savedAdmin = userRepository.save(admin);

        // 3. Return a UserDTO (same shape as login response)
        // so Flutter can navigate to admin dashboard immediately
        String token = jwtUtils.generateToken(UserPrincipal.from(savedAdmin));

        return new UserDTO(
                savedAdmin.getFirstName(),   // firstName
                savedAdmin.getLastName(),    // lastName
                savedAdmin.getEmail(),       // email
                null,                        // programmeId
                null,                        // programmeName
                token,                       // token
                savedAdmin.getRole().name(), // role
                saved.getId(),               // institutionId
                saved.getName()

                );
    }

    public List<InstitutionDto> getInstitutions() {
        return institutionRepository.findAll()
                .stream()
                .map(i -> {
                    InstitutionDto dto = new InstitutionDto();
                    dto.setId(i.getId());
                    dto.setName(i.getName());
                    return dto;
                })
                .collect(Collectors.toList());
    }

}