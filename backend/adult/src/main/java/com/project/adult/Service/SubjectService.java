package com.project.adult.Service;

import com.project.adult.DTO.SubjectDTO;
import com.project.adult.Model.Course;
import com.project.adult.Repository.subjectRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service layer for managing {@link Course} entities from the "subject"
 * perspective (courses viewed within the context of a programme).
 */
@Service
public class SubjectService {
    final subjectRepository subjectRepository;

    /**
     * Constructs the service with its required repository.
     *
     * @param subjectRepository repository for persisting and querying subjects/courses
     */
    public SubjectService(subjectRepository subjectRepository) {
        this.subjectRepository = subjectRepository;
    }

    /**
     * Retrieves all subjects (courses) belonging to a given programme.
     *
     * @param programmeId the id of the programme to fetch subjects for
     * @return a list of {@link SubjectDTO} for the given programme
     */
    public List<SubjectDTO> getAlldetailsById(Long programmeId){
        return subjectRepository.findCoursesByProgrammeId(programmeId)
                .stream()
                .map(p-> new SubjectDTO(p.getId(),p.getCourseCode(),p.getDescription(),p.getName(),programmeId))
                .collect(Collectors.toList());

    }

    /**
     * Retrieves all subjects (courses) in the system.
     *
     * @return a list of all {@link Course} entities
     */
    public List<Course> getAllSubjects(){
        return subjectRepository.findAll();
    }
}