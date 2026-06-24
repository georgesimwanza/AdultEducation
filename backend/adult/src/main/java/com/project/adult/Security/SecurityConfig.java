package com.project.adult.Security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final UserDetailsServiceImpl userDetailsService;
    private final JwtFilter jwtFilter;

    public SecurityConfig(UserDetailsServiceImpl userDetailsService,
                          JwtFilter jwtFilter) {
        this.userDetailsService = userDetailsService;
        this.jwtFilter          = jwtFilter;
    }

    // -------------------------------------------------------------------------
    // PasswordEncoder
    // IMPORTANT: your passwordHash column must store BCrypt hashes.
    // When registering a new user, encode with:
    //   user.setPasswordHash(passwordEncoder.encode(rawPassword));
    // Never store plain text.
    // -------------------------------------------------------------------------

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }

    // -------------------------------------------------------------------------
    // DaoAuthenticationProvider
    // Wires your UserDetailsServiceImpl + BCryptPasswordEncoder together.
    // On login it calls:
    //   1. userDetailsService.loadUserByUsername(email)
    //   2. passwordEncoder.matches(rawPassword, storedHash)
    // -------------------------------------------------------------------------

    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        // Spring Security 6: UserDetailsService is passed into the constructor,
        // not set via a setter. PasswordEncoder is set via the remaining setter.
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    // -------------------------------------------------------------------------
    // AuthenticationManager — inject this into your AuthController to
    // manually call authenticate() on the /login endpoint.
    // -------------------------------------------------------------------------

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    // -------------------------------------------------------------------------
    // Security filter chain
    // -------------------------------------------------------------------------

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())              // stateless JWT — no CSRF needed

                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                .authorizeHttpRequests(auth -> auth

                        // Auth endpoints
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/api/users/login").permitAll()
                        .requestMatchers("/api/users/Register").permitAll()
                        .requestMatchers("/api/users/AllStudents").hasRole("ADMIN")
                        .requestMatchers("/api/institution/**").permitAll()

                        // Programmes
                        .requestMatchers(HttpMethod.GET, "/api/programmes/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/Content/**").permitAll()
                        .requestMatchers("/api/sync/**").permitAll()

                        // Content — specific rules BEFORE broad ones
                        .requestMatchers(HttpMethod.POST, "/api/Content/addContent").permitAll()
                        .requestMatchers(HttpMethod.GET,  "/api/Content/**").permitAll()

                        // Subject
                        .requestMatchers("/api/subject/programme/**").permitAll()
                        .requestMatchers("/api/subject/allSubjects").hasRole("ADMIN")
                        .requestMatchers("/api/subject/addSubject").hasRole("ADMIN")
                        .anyRequest().authenticated()
                )

                .authenticationProvider(authenticationProvider())

                // JWT filter runs before Spring's own credential filter.
                // It reads the Authorization header, validates the token, and
                // sets the SecurityContext — so the request arrives at your
                // controller already authenticated.
                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}