package com.project.adult.Service;

import com.project.adult.DTO.RegisterRequest;
import com.project.adult.DTO.UserDTO;
import com.project.adult.Model.Programme;
import com.project.adult.Model.User;
import com.project.adult.Repository.ProgrammeRepository;
import com.project.adult.Repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final ProgrammeRepository programmeRepository;

    public UserService(UserRepository userRepository, ProgrammeRepository programmeRepository) {
        this.userRepository = userRepository;
        this.programmeRepository = programmeRepository;
    }

    @Transactional
    public User CreateUser(RegisterRequest request) {
        User user = new User();
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setEmail(request.getEmail());
        user.setPasswordHash(request.getPasswordHash());

        // Look up the actual managed Programme entity by ID
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

        if (!user.getPasswordHash().equals(password)) {
            throw new RuntimeException("Invalid password");
        }

        return new UserDTO(
                user.getFirstName(),
                user.getLastName(),
                user.getEmail(),
                user.getSelectedProgramme().getId(),
                user.getSelectedProgramme().getName()
        );
    }
}