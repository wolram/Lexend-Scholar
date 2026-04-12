package com.lexendscholar.app.ui.academic

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.lexendscholar.app.data.model.Student

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StudentDetailPane(
    student: Student,
    isFullScreen: Boolean,
    onBack: () -> Unit
) {
    Scaffold(
        topBar = {
            if (isFullScreen) {
                TopAppBar(
                    title = { Text(student.name) },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                        }
                    }
                )
            } else {
                TopAppBar(title = { Text("Student Detail") })
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Text(student.name, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
                Text(student.grade, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            item { HorizontalDivider() }
            item {
                StudentInfoRow("Student Number", student.studentNumber)
                StudentInfoRow("Department", student.department)
                StudentInfoRow("Email", student.email)
                StudentInfoRow("Status", student.status)
            }
            item { HorizontalDivider() }
            item {
                Text("Academic Performance", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.height(8.dp))
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    AcademicStat(modifier = Modifier.weight(1f), label = "GPA", value = student.gpa.toString())
                    AcademicStat(modifier = Modifier.weight(1f), label = "Attendance", value = "${student.attendanceRate}%")
                }
            }
        }
    }
}

@Composable
private fun StudentInfoRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
        Text(label, modifier = Modifier.weight(0.4f), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, modifier = Modifier.weight(0.6f), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
    }
}

@Composable
private fun AcademicStat(modifier: Modifier = Modifier, label: String, value: String) {
    Card(modifier = modifier) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text(label, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

// LS-157: Multi-pane layout for tablets — StudentDetailPane renders in detail pane
// of ListDetailPaneScaffold. isFullScreen flag controls back button visibility.
// Tablet shows list+detail simultaneously; phone shows each full-screen.
