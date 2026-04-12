package com.marlow.lexendscholar.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.marlow.lexendscholar.ui.auth.LoginScreen
import com.marlow.lexendscholar.ui.academic.StudentsScreen
import com.marlow.lexendscholar.data.Student

sealed class Screen(val route: String) {
    object Login : Screen("login")
    object Students : Screen("students")
    object Attendance : Screen("attendance")
    object Grades : Screen("grades")
}

@Composable
fun AppNavigation() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = Screen.Login.route) {
        composable(Screen.Login.route) {
            LoginScreen(onLoginSuccess = {
                navController.navigate(Screen.Students.route) {
                    popUpTo(Screen.Login.route) { inclusive = true }
                }
            })
        }
        composable(Screen.Students.route) {
            StudentsScreen(students = emptyList())
        }
    }
}
