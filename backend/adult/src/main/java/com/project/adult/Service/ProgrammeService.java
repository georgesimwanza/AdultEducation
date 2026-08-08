package com.project.adult.Service;

import com.project.adult.DTO.ProgrammeDTO;
import com.project.adult.Repository.ProgrammeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.List;
import java.util.stream.Collectors;

// ProgrammeService.java
/**
 * Service layer for managing {@link com.project.adult.Model.Programme} entities.
 * <p>
 * Provides read-only access to programme data via {@link ProgrammeDTO}.
 */
@Service
@RequiredArgsConstructor
public class ProgrammeService {

    private final ProgrammeRepository programmeRepository;

    /**
     * Retrieves all programmes in the system.
     *
     * @return a list of {@link ProgrammeDTO} for every programme
     */
    public List<ProgrammeDTO> getAllProgrammes() {
        return programmeRepository.findAll()
                .stream()
                .map(p -> new ProgrammeDTO(p.getId(), p.getName(), p.getDescription()))
                .collect(Collectors.toList());
    }

    /**
     * Retrieves the name/title of a programme by its identifier.
     *
     * @param id the programme id
     * @return the programme's name
     * @throws RuntimeException if no programme exists with the given id
     */
    public String getTitleById(Long id) {
        return programmeRepository.findById(id)
                .map(p -> p.getName())
                .orElseThrow(() -> new RuntimeException("Programme not found with id: " + id));
    }

}