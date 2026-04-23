package com.project.adult.Service;

import com.project.adult.DTO.ProgrammeDTO;
import com.project.adult.Repository.ProgrammeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.List;
import java.util.stream.Collectors;

// ProgrammeService.java
@Service
@RequiredArgsConstructor
public class ProgrammeService {

    private final ProgrammeRepository programmeRepository;

    public List<ProgrammeDTO> getAllProgrammes() {
        return programmeRepository.findAll()
                .stream()
                .map(p -> new ProgrammeDTO(p.getId(), p.getName(), p.getDescription()))
                .collect(Collectors.toList());
    }

    public String getTitleById(Long id) {
        return programmeRepository.findById(id)
                .map(p -> p.getName())
                .orElseThrow(() -> new RuntimeException("Programme not found with id: " + id));
    }

}