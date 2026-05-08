package com.project.adult.Security;

import com.project.adult.Model.User;
import jakarta.persistence.Enumerated;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

/**
 * Adapts your User entity to Spring Security's UserDetails contract.
 *
 * Key differences from the generic template:
 *  - Your User logs in with EMAIL, not a username field.
 *  - The password column is called passwordHash, not password.
 *  - You have no Role entity yet, so every user gets ROLE_USER by default.
 *    Add a roles relationship to User later and update from() accordingly.
 *
 * Retrieve the logged-in user anywhere in your code:
 *   UserPrincipal principal = (UserPrincipal)
 *       SecurityContextHolder.getContext().getAuthentication().getPrincipal();
 */
public class UserPrincipal implements UserDetails {

    private final Long id;
    private final String email;
    private final String passwordHash;
    private final boolean enabled;
    private final Collection<? extends GrantedAuthority> authorities;

    private UserPrincipal(Builder builder) {
        this.id           = builder.id;
        this.email        = builder.email;
        this.passwordHash = builder.passwordHash;
        this.enabled      = builder.enabled;
        this.authorities  = builder.authorities;
    }


    // -------------------------------------------------------------------------
    // Factory — maps your actual User fields
    // -------------------------------------------------------------------------

    public static UserPrincipal from(User user) {
        // No Role entity yet — every authenticated user gets ROLE_USER.
        // When you add roles to User, replace this list with:
        //   user.getRoles().stream()
        //       .map(r -> new SimpleGrantedAuthority("ROLE_" + r.getName()))
        //       .collect(Collectors.toList())
        List<GrantedAuthority> authorities = List.of(
                new SimpleGrantedAuthority("ROLE_"+ user.getRole().name())
        );

        return new Builder()
                .id(user.getId())
                .email(user.getEmail())
                .passwordHash(user.getPasswordHash())   // matches your @Column("password_hash")
                .enabled(user.getIsActive() != null && user.getIsActive())
                .authorities(authorities)
                .build();
    }

    // -------------------------------------------------------------------------
    // UserDetails contract
    //
    // Spring Security calls getUsername() to identify the principal.
    // We return the email because that is what your app uses to log in.
    // -------------------------------------------------------------------------

    @Override
    public String getUsername() {
        return email;   // email IS the username in your domain
    }

    @Override
    public String getPassword() {
        return passwordHash;   // must return the encoded hash, not a plain password
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override public boolean isEnabled()               { return enabled; }
    @Override public boolean isAccountNonLocked()      { return true; }
    @Override public boolean isAccountNonExpired()     { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }

    // -------------------------------------------------------------------------
    // Extra helpers
    // -------------------------------------------------------------------------

    public Long getId()      { return id; }
    public String getEmail() { return email; }

    // -------------------------------------------------------------------------
    // Builder
    // -------------------------------------------------------------------------

    public static class Builder {
        private Long id;
        private String email;
        private String passwordHash;
        private boolean enabled = true;
        private Collection<? extends GrantedAuthority> authorities = List.of();

        public Builder id(Long id)                     { this.id = id; return this; }
        public Builder email(String email)             { this.email = email; return this; }
        public Builder passwordHash(String hash)       { this.passwordHash = hash; return this; }
        public Builder enabled(boolean enabled)        { this.enabled = enabled; return this; }
        public Builder authorities(Collection<? extends GrantedAuthority> a) { this.authorities = a; return this; }

        public UserPrincipal build() {
            if (email == null)        throw new IllegalStateException("email is required");
            if (passwordHash == null) throw new IllegalStateException("passwordHash is required");
            return new UserPrincipal(this);
        }
    }
}