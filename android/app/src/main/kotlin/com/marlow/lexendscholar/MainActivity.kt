package com.marlow.lexendscholar

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.marlow.lexendscholar.navigation.AppNavigation
import com.marlow.lexendscholar.ui.theme.LexendScholarTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            LexendScholarTheme {
                AppNavigation()
            }
        }
    }
}
