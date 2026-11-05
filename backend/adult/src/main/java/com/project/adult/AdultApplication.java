package com.project.adult;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

// Scheduling runs the hourly deadline-reminder job in NotificationService
@SpringBootApplication
@EnableScheduling
public class AdultApplication {

	public static void main(String[] args) {
		SpringApplication.run(AdultApplication.class, args);
	}

}
