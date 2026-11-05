package com.project.adult.Security;

import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Slows down password guessing: after 5 failed logins for an email within
 * 15 minutes, that email is locked out for 15 minutes. Kept in memory, so
 * the counters reset when the server restarts.
 */
@Service
public class LoginAttemptService {

    private static final int MAX_FAILURES = 5;
    private static final Duration WINDOW = Duration.ofMinutes(15);

    private record Attempts(int failures, Instant firstFailure) {
    }

    private final Map<String, Attempts> attempts = new ConcurrentHashMap<>();

    public boolean isBlocked(String email) {
        Attempts a = attempts.get(key(email));
        if (a == null) return false;
        if (a.firstFailure().plus(WINDOW).isBefore(Instant.now())) {
            attempts.remove(key(email));
            return false;
        }
        return a.failures() >= MAX_FAILURES;
    }

    public void recordFailure(String email) {
        attempts.merge(key(email), new Attempts(1, Instant.now()), (old, n) ->
                old.firstFailure().plus(WINDOW).isBefore(Instant.now())
                        ? n
                        : new Attempts(old.failures() + 1, old.firstFailure()));
    }

    public void recordSuccess(String email) {
        attempts.remove(key(email));
    }

    private static String key(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }
}
