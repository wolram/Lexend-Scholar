package com.lexendscholar.app.data.repository

import com.lexendscholar.app.data.model.AuthState
import com.lexendscholar.app.data.model.UserRole
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.user.UserInfo
import io.github.jan.supabase.postgrest.Postgrest
import kotlinx.serialization.json.jsonPrimitive
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val auth: Auth,
    private val postgrest: Postgrest
) {

    suspend fun signIn(email: String, password: String): AuthState {
        return try {
            auth.signInWith(Email) {
                this.email = email
                this.password = password
            }
            val user = auth.currentUserOrNull()
            mapUserToAuthState(user)
        } catch (e: Exception) {
            AuthState.Error(e.message ?: "Authentication failed")
        }
    }

    suspend fun signOut() {
        try {
            auth.signOut()
        } catch (_: Exception) {}
    }

    suspend fun getCurrentSession(): AuthState {
        return try {
            auth.awaitInitialization()
            val user = auth.currentUserOrNull()
            if (user != null) {
                mapUserToAuthState(user)
            } else {
                AuthState.Unauthenticated
            }
        } catch (e: Exception) {
            AuthState.Unauthenticated
        }
    }

    private fun mapUserToAuthState(user: UserInfo?): AuthState {
        if (user == null) return AuthState.Unauthenticated
        val roleString = user.userMetadata?.get("role")?.jsonPrimitive?.content
        return AuthState.Authenticated(
            userId = user.id,
            email = user.email ?: "",
            role = UserRole.fromString(roleString)
        )
    }
}

// LS-153: Supabase Android SDK integration with email/password auth and role-based profiles
// Supports: admin, teacher, guardian, student roles via user_metadata.role
