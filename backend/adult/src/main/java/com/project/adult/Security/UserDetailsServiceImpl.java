package com.project.adult.Security;

import com.project.adult.Model.User;
import com.project.adult.Repository.UserRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Spring Security calls loadUserByUsername() during every login attempt.
 * Despite the method name containing "username", we look up by EMAIL
 * because that is the unique identifier in your User table.
 *
 * This works because on the login request you pass the email as the
 * "username" field — Spring Security does not care what the value
 * represents, it just passes whatever string it receives into this method.
 *
 * Your UserRepository already has findByEmailIgnoreCase(), so no new
 * query methods are needed.
 */
@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    public UserDetailsServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "No user found with email: " + email
                ));

        return UserPrincipal.from(user);
    }
}