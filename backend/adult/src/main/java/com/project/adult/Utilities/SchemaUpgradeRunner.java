package com.project.adult.Utilities;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Database changes that spring.jpa.hibernate.ddl-auto=update can't make
 * by itself. Every statement is safe to run on each startup.
 */
@Component
public class SchemaUpgradeRunner implements ApplicationRunner {

    private final JdbcTemplate jdbc;

    public SchemaUpgradeRunner(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void run(ApplicationArguments args) {
        // Hibernate created a CHECK constraint listing the original roles;
        // "update" never widens it, so INSTRUCTOR accounts would be rejected.
        run("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check");

        // Learners who signed up before course enrollment existed: enroll
        // them in their programme's courses. Rows they dropped stay dropped.
        run("""
                INSERT INTO enrollments (user_id, course_id, status, enrolled_at)
                SELECT u.id, pc.course_id, 'ACTIVE', now()
                FROM users u
                JOIN programme_courses pc ON pc.programme_id = u.selected_programme_id
                WHERE u.role = 'USER'
                  AND NOT EXISTS (SELECT 1 FROM enrollments e
                                  WHERE e.user_id = u.id AND e.course_id = pc.course_id)
                """);
    }

    private void run(String sql) {
        try {
            jdbc.execute(sql);
        } catch (Exception e) {
            System.err.println("Schema upgrade step skipped: " + e.getMessage());
        }
    }
}
