package com.project.adult.DTO;

import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Body of PUT /api/account/password.
 * <p>
 * Deliberately has no all-args constructor: Jackson then uses the no-arg
 * constructor plus setters, so a missing field is just null and the service
 * layer reports it with a clear message.
 */
@Data
@NoArgsConstructor
public class ChangePasswordRequest {
    private String currentPassword;
    private String newPassword;
}