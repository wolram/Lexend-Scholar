package com.lexendscholar.app.data.model

sealed class AuthState {
    object Loading : AuthState()
    object Unauthenticated : AuthState()
    data class Authenticated(
        val userId: String,
        val email: String,
        val role: UserRole
    ) : AuthState()
    data class Error(val message: String) : AuthState()
}

enum class UserRole {
    ADMIN,
    TEACHER,
    GUARDIAN,
    STUDENT;

    companion object {
        fun fromString(value: String?): UserRole = when (value?.lowercase()) {
            "admin" -> ADMIN
            "teacher" -> TEACHER
            "guardian" -> GUARDIAN
            "student" -> STUDENT
            else -> STUDENT
        }
    }
}
