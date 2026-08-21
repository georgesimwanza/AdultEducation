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

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }

    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())

                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                .authorizeHttpRequests(auth -> auth

                        // Auth endpoints
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/api/users/login").permitAll()
                        .requestMatchers("/api/users/Register").permitAll()
                        .requestMatchers("/api/users/AllStudents").hasRole("ADMIN")
                        .requestMatchers("/api/institution/**").permitAll()
                        .requestMatchers("/api/users/institution/**").permitAll()
                        .requestMatchers("/api/users/count/**").permitAll()

                        // Programmes
                        .requestMatchers(HttpMethod.GET, "/api/programmes/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/Content/**").permitAll()
                        .requestMatchers("/api/sync/**").permitAll()

                        // Content — specific rules BEFORE broad ones
                        .requestMatchers(HttpMethod.POST, "/api/Content/addContent").permitAll()
                        .requestMatchers(HttpMethod.GET,  "/api/Content/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/announcement/allAnnouncements").permitAll()
                        // ← added: this was falling through to anyRequest().authenticated(),
                        // which is where the 403 on the notices screen was coming from.
                        .requestMatchers(HttpMethod.GET, "/api/announcement/getByInstitutionAndProgramme").permitAll()

                        // Writes restricted to ADMIN
                        .requestMatchers(HttpMethod.POST, "/api/announcement/addAnnouncement").permitAll()
                        .requestMatchers(HttpMethod.DELETE, "/api/announcement/delete/**").permitAll()
                        //quiz permissions
                        .requestMatchers("/api/quizzes/**").permitAll()
                        // Subject
                        .requestMatchers("/api/subject/programme/**").permitAll()
                        .requestMatchers("/api/subject/allSubjects").hasRole("ADMIN")
                        .requestMatchers("/api/subject/addSubject").hasRole("ADMIN")
                        .anyRequest().authenticated()


                )

                .authenticationProvider(authenticationProvider())

                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}