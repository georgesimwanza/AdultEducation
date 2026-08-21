package com.project.adult.Service;

import com.project.adult.DTO.ScheduleDTO;
import com.project.adult.Model.Schedule;
import com.project.adult.Repository.ScheduleRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service layer for managing {@link Schedule} entities.
 * <p>
 * Provides creation, per-user retrieval, and deletion of schedule entries,
 * converting persisted entities to {@link ScheduleDTO} for API responses.
 */
@Service
public class ScheduleService {

    private final ScheduleRepository scheduleRepository;

    /**
     * Constructs the service with its required repository.
     *
     * @param scheduleRepository repository for persisting and querying schedules
     */
    public ScheduleService(ScheduleRepository scheduleRepository) {
        this.scheduleRepository = scheduleRepository;
    }

    /**
     * Converts a {@link Schedule} entity to its DTO representation.
     *
     * @param schedule the entity to convert
     * @return the corresponding {@link ScheduleDTO}
     */
    // Convert Model → DTO
    private ScheduleDTO toDTO(Schedule schedule) {
        return new ScheduleDTO(
                schedule.getId(),
                schedule.getTitle(),
                schedule.getUserEmail(),
                schedule.getDate(),
                schedule.getStartTime(),
                schedule.getEndTime()
        );
    }

    /**
     * Creates and persists a new schedule entry.
     *
     * @param schedule the schedule to create
     * @return the saved schedule as a {@link ScheduleDTO}
     */
    // POST — save new schedule
    public ScheduleDTO addSchedule(Schedule schedule) {
        Schedule saved = scheduleRepository.save(schedule);
        return toDTO(saved);
    }

    /**
     * Retrieves all schedule entries belonging to a given user.
     *
     * @param email the email address of the user whose schedules to fetch
     * @return a list of {@link ScheduleDTO} for the given user
     */
    // GET — fetch all schedules for a user
    public List<ScheduleDTO> getSchedulesByEmail(String email) {
        return scheduleRepository.findByUserEmail(email)
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    /**
     * Deletes a schedule entry by its identifier.
     *
     * @param id the id of the schedule to delete
     */
    // DELETE — remove by id
    public void deleteSchedule(Long id) {
        scheduleRepository.deleteById(id);
    }
}