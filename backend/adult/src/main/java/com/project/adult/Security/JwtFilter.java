package com.project.adult.Security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Runs once per request, before Spring Security's own filters.
 *
 * What it does:
 *   1. Reads the Authorization header — expects "Bearer <token>"
 *   2. Extracts the email from the token
 *   3. Loads the UserDetails from the DB
 *   4. Validates the token against the UserDetails
 *   5. If valid, sets the Authentication in the SecurityContext
 *      so the rest of the filter chain sees an authenticated request
 *
 * If anything is missing or invalid it does nothing — the request
 * continues unauthenticated and hits the 401 wall at the
 * AuthorizationFilter if the route is protected.
 */
@Component
public class JwtFilter extends OncePerRequestFilter {

    private final JwtUtils jwtUtils;
    private final UserDetailsServiceImpl userDetailsService;

    public JwtFilter(JwtUtils jwtUtils, UserDetailsServiceImpl userDetailsService) {
        this.jwtUtils           = jwtUtils;
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");

        // ── 1. No header or wrong format → skip, continue chain ──────────────
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // ── 2. Strip "Bearer " prefix ─────────────────────────────────────────
        final String token = authHeader.substring(7);

        // ── 3. Extract email from token ───────────────────────────────────────
        final String email;
        try {
            email = jwtUtils.extractEmail(token);
        } catch (Exception e) {
            // Malformed or tampered token — treat as unauthenticated
            filterChain.doFilter(request, response);
            return;
        }

        // ── 4. Only proceed if we got an email and context is not yet set ──────
        //    If SecurityContext already has an Authentication (e.g. from a
        //    previous filter), we leave it alone.
        if (email != null && SecurityContextHolder.getContext().getAuthentication() == null) {

            // Loads from DB — confirms the user still exists and is active
            UserDetails userDetails = userDetailsService.loadUserByUsername(email);

            // ── 5. Validate token signature + expiry + email match ────────────
            if (jwtUtils.isTokenValid(token, userDetails)) {

                // ── 6. Build an authenticated token and put it in the context ──
                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,                        // credentials null — we don't need the password anymore
                                userDetails.getAuthorities()
                        );

                // Attaches IP address, session id etc. to the authentication
                authToken.setDetails(
                        new WebAuthenticationDetailsSource().buildDetails(request)
                );

                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        // ── 7. Continue — request is now authenticated (or not, if token was bad)
        filterChain.doFilter(request, response);
    }
}