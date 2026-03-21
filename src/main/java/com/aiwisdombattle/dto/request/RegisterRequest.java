package com.aiwisdombattle.dto.request;

import jakarta.validation.constraints.*;
import lombok.Getter;

@Getter
public class RegisterRequest {

    @NotBlank
    @Email
    @Size(max = 100)
    private String email;

    @NotBlank
    @Size(min = 2, max = 50)
    private String displayName;

    /**
     * Mật khẩu: tối thiểu 8 ký tự, ít nhất 1 chữ hoa, 1 chữ thường, 1 chữ số.
     * Validation thêm được thực hiện trong AuthService.
     */
    @NotBlank
    @Size(min = 8, max = 72)   // 72 là giới hạn của BCrypt
    private String password;

    /** nature | technology | history | creative */
    @NotBlank
    @Pattern(regexp = "nature|technology|history|creative",
             message = "explorerType phải là: nature, technology, history, creative")
    private String explorerType;

    /** child_8_10 | teen_11_17 | adult_18_plus */
    @NotBlank
    @Pattern(regexp = "child_8_10|teen_11_17|adult_18_plus",
             message = "ageGroup phải là: child_8_10, teen_11_17, adult_18_plus")
    private String ageGroup;
}
