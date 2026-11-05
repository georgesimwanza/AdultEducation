package com.project.adult.Security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
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
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    // Roles that create and manage teaching material
    private static final String[] STAFF = {"ADMIN", "INSTRUCTOR", "INSTITUTION"};

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

    // Lets the Flutter web build (and the React app) call the API from any
    // localhost port during development.
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("http://localhost:*", "http://127.0.0.1:*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(csrf -> csrf.disable())

                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // A missing or expired token is 401 (sign in again), not 403
                // (signed in but not allowed), so the app can tell them apart.
                .exceptionHandling(e -> e.authenticationEntryPoint(
                        new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))

                .authorizeHttpRequests(auth -> auth

                        // CORS preflight never carries a token
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // Error responses keep their real status (403 for a
                        // forbidden page) instead of turning into 401.
                        .requestMatchers("/error").permitAll()

                        // Auth endpoints
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/api/users/login").permitAll()
                        .requestMatchers("/api/users/Register").permitAll()
                        .requestMatchers("/api/health").permitAll()
                        .requestMatchers("/api/users/AllStudents").hasAnyRole("ADMIN", "INSTITUTION")
                        .requestMatchers("/api/institution/**").permitAll()
                        // User lists hold personal data: staff only
                        .requestMatchers("/api/users/institution/**").hasAnyRole(STAFF)
                        .requestMatchers("/api/users/count/**").authenticated()

                        // Programmes
                        .requestMatchers(HttpMethod.GET, "/api/programmes/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/Content/**").permitAll()
                        .requestMatchers("/api/sync/**").permitAll()

                        // Content — specific rules BEFORE broad ones
                        .requestMatchers(HttpMethod.POST, "/api/Content/addContent").hasAnyRole(STAFF)
                        .requestMatchers(HttpMethod.GET,  "/api/Content/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/announcement/allAnnouncements").permitAll()
                        // ← added: this was falling through to anyRequest().authenticated(),
                        // which is where the 403 on the notices screen was coming from.
                        .requestMatchers(HttpMethod.GET, "/api/announcement/getByInstitutionAndProgramme").permitAll()

                        // Writes restricted to staff
                        .requestMatchers(HttpMethod.POST, "/api/announcement/addAnnouncement").hasAnyRole(STAFF)
                        .requestMatchers(HttpMethod.DELETE, "/api/announcement/delete/**").hasAnyRole(STAFF)
                        //quiz permissions: anyone can read, only staff can change
                        .requestMatchers(HttpMethod.GET, "/api/quizzes/**").permitAll()
                        .requestMatchers("/api/quizzes/**").hasAnyRole(STAFF)
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