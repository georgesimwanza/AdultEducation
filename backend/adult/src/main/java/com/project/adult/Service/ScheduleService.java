package com.project.adult.Service;

import com.project.adult.DTO.ScheduleDTO;
import com.project.adult.Model.Schedule;
import com.project.adult.Repository.ScheduleRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ScheduleService {

    private final ScheduleRepository scheduleRepository;

    public ScheduleService(ScheduleRepository scheduleRepository) {
        this.scheduleRepository = scheduleRepository;
    }

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

    // POST — save new schedule
    public ScheduleDTO addSchedule(Schedule schedule) {
        Schedule saved = scheduleRepository.save(schedule);
        return toDTO(saved);
    }

    // GET — fetch all schedules for a user
    public List<ScheduleDTO> getSchedulesByEmail(String email) {
        return scheduleRepository.findByUserEmail(email)
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    // DELETE — remove by id
    public void deleteSchedule(Long id) {
        scheduleRepository.deleteById(id);
    }
}