package com.lexendscholar.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.material3.windowsizeclass.ExperimentalMaterial3WindowSizeClassApi
import androidx.compose.material3.windowsizeclass.calculateWindowSizeClass
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.WorkManager
import com.lexendscholar.app.sync.SyncWorker
import com.lexendscholar.app.ui.navigation.AppNavigation
import com.lexendscholar.app.ui.theme.LexendScholarTheme
import com.lexendscholar.app.viewmodel.AuthViewModel
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @OptIn(ExperimentalMaterial3WindowSizeClassApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // LS-155: Schedule periodic background sync
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            SyncWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            SyncWorker.periodicRequest()
        )

        setContent {
            LexendScholarTheme {
                val authViewModel: AuthViewModel = hiltViewModel()
                val authState by authViewModel.authState.collectAsState()
                // LS-156: Pass WindowSizeClass into navigation for adaptive layouts
                val windowSizeClass = calculateWindowSizeClass(this)
                AppNavigation(
                    authState = authState,
                    authViewModel = authViewModel,
                    windowSizeClass = windowSizeClass
                )
            }
        }
    }
}
