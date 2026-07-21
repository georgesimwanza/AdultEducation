package com.project.adult.Security;

import com.project.adult.Model.User;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

public class UserPrincipal implements UserDetails {

    private final Long id;
    private final String email;
    private final String passwordHash;
    private final boolean enabled;
    private final Long institutionId; // NEW
    private final Collection<? extends GrantedAuthority> authorities;

    private UserPrincipal(Builder builder) {
        this.id            = builder.id;
        this.email         = builder.email;
        this.passwordHash  = builder.passwordHash;
        this.enabled       = builder.enabled;
        this.institutionId = builder.institutionId; // NEW
        this.authorities   = builder.authorities;
    }

    public static UserPrincipal from(User user) {
        List<GrantedAuthority> authorities = List.of(
                new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
        );

        return new Builder()
                .id(user.getId())
                .email(user.getEmail())
                .passwordHash(user.getPasswordHash())
                .enabled(user.getIsActive() != null && user.getIsActive())
                // Adjust this line to match your actual User -> Institution relation.
                // If User has `private Institution institution;`, this works as-is.
                // If it instead stores a raw `private Long institutionId;`, use
                // .institutionId(user.getInstitutionId()) instead.
                .institutionId(user.getInstitution() != null ? user.getInstitution().getId().longValue() : null)
                .authorities(authorities)
                .build();
    }

    @Override
    public String getUsername() { return email; }

    @Override
    public String getPassword() { return passwordHash; }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() { return authorities; }

    @Override public boolean isEnabled()               { return enabled; }
    @Override public boolean isAccountNonLocked()      { return true; }
    @Override public boolean isAccountNonExpired()     { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }

    public Long getId()            { return id; }
    public String getEmail()       { return email; }
    public Long getInstitutionId() { return institutionId; } // NEW

    public static class Builder {
        private Long id;
        private String email;
        private String passwordHash;
        private boolean enabled = true;
        private Long institutionId; // NEW
        private Collection<? extends GrantedAuthority> authorities = List.of();

        public Builder id(Long id)               { this.id = id; return this; }
        public Builder email(String email)       { this.email = email; return this; }
        public Builder passwordHash(String hash) { this.passwordHash = hash; return this; }
        public Builder enabled(boolean enabled)  { this.enabled = enabled; return this; }
        public Builder institutionId(Long institutionId) { this.institutionId = institutionId; return this; } // NEW
        public Builder authorities(Collection<? extends GrantedAuthority> a) { this.authorities = a; return this; }

        public UserPrincipal build() {
            if (email == null)        throw new IllegalStateException("email is required");
            if (passwordHash == null) throw new IllegalStateException("passwordHash is required");
            return new UserPrincipal(this);
        }
    }
}