package com.project.adult.Service;

import com.project.adult.DTO.InstitutionDto;
import com.project.adult.Model.Institution;
import com.project.adult.Repository.InstitutionRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class institutionService {

    private final InstitutionRepository institutionRepository;

    public institutionService(InstitutionRepository institutionRepository) {
        this.institutionRepository = institutionRepository;
    }

    public Institution registerInstitution(Institution institution) {
        if (institutionRepository.existsByName(institution.getName())) {
            throw new RuntimeException("Institution already exists");
        }
        return institutionRepository.save(institution);
    }

    public List<InstitutionDto> getInstitutions() {
        return institutionRepository.findAll()
                .stream()
                .map(i->{
                    InstitutionDto dto = new InstitutionDto();
                    dto.setId(i.getId());
                    dto.setName(i.getName());
                    return dto;
                })
                .collect(Collectors.toList());
    }
}