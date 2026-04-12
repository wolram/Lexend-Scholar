package com.lexendscholar.app.ui.navigation

import androidx.compose.material3.windowsizeclass.WindowSizeClass
import androidx.compose.runtime.Composable
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.lexendscholar.app.data.model.AuthState
import com.lexendscholar.app.ui.adaptive.AdaptiveStudentLayout
import com.lexendscholar.app.ui.auth.LoginScreen
import com.lexendscholar.app.ui.dashboard.DashboardScreen
import com.lexendscholar.app.viewmodel.AcademicViewModel
import com.lexendscholar.app.viewmodel.AuthViewModel

sealed class Screen(val route: String) {
    object Login : Screen("login")
    object Dashboard : Screen("dashboard")
    object Students : Screen("students")
    object Attendance : Screen("attendance/{classId}") {
        fun createRoute(classId: String) = "attendance/$classId"
    }
    object Grades : Screen("grades/{studentId}") {
        fun createRoute(studentId: String) = "grades/$studentId"
    }
}

@Composable
fun AppNavigation(
    authState: AuthState,
    authViewModel: AuthViewModel,
    windowSizeClass: WindowSizeClass
) {
    val navController = rememberNavController()

    val startDestination = when (authState) {
        is AuthState.Authenticated -> Screen.Dashboard.route
        else -> Screen.Login.route
    }

    NavHost(navController = navController, startDestination = startDestination) {
        composable(Screen.Login.route) {
            LoginScreen(
                authViewModel = authViewModel,
                onLoginSuccess = {
                    navController.navigate(Screen.Dashboard.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                }
            )
        }
        composable(Screen.Dashboard.route) {
            DashboardScreen(
                authViewModel = authViewModel,
                onNavigate = { route -> navController.navigate(route) }
            )
        }
        // LS-156 + LS-157: Adaptive student layout with list+detail for tablets
        composable(Screen.Students.route) {
            val academicViewModel: AcademicViewModel = hiltViewModel()
            AdaptiveStudentLayout(
                viewModel = academicViewModel,
                windowSizeClass = windowSizeClass,
                onBack = { navController.popBackStack() }
            )
        }
    }
}
