package com.project.adult.Service;

import com.project.adult.DTO.SubjectDTO;
import com.project.adult.Repository.subjectRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class SubjectService {
 final subjectRepository subjectRepository;

    public SubjectService(subjectRepository subjectRepository) {
        this.subjectRepository = subjectRepository;
    }

    public List<SubjectDTO> getAlldetailsById(Long programmeId){
        return subjectRepository.findCoursesByProgrammeId(programmeId)
                .stream()
                .map(p-> new SubjectDTO(p.getCourseCode(),p.getDescription(),p.getName()))
                .collect(Collectors.toList());

    }
}
