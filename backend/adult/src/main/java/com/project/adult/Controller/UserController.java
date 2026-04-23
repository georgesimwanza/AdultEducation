package com.project.adult.Controller;

import com.project.adult.DTO.LoginRequest;
import com.project.adult.DTO.RegisterRequest;
import com.project.adult.DTO.UserDTO;
import com.project.adult.Model.User;
import com.project.adult.Service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@CrossOrigin
@RestController
@RequestMapping("/api/users")
public class UserController {

private final UserService userService;
public UserController(UserService userService){
    this.userService= userService;
}
    @PostMapping("/Register")
    public ResponseEntity<?> createUser(@RequestBody RegisterRequest request) {
        System.out.println(">>> Programme ID received: " +
                (request.getSelectedProgramme() != null
                        ? request.getSelectedProgramme().getId()
                        : "NULL"));
        try {
            User user = userService.CreateUser(request);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.status(400).body(e.getMessage());
        }
    }
@PostMapping("/login")
    public ResponseEntity<?>login(@RequestBody LoginRequest loginRequest){
    try{
        UserDTO user = userService.login(loginRequest.getEmail(),loginRequest.getPassword());
                return ResponseEntity.ok(user);
    } catch (RuntimeException e) {
        return ResponseEntity.status(401).body(e.getMessage());
    }
}
}
