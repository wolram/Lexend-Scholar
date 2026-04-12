package com.lexendscholar.app.ui.academic

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.lexendscholar.app.data.model.Grade
import com.lexendscholar.app.viewmodel.AcademicViewModel
import kotlinx.coroutines.flow.emptyFlow

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GradesScreen(
    viewModel: AcademicViewModel,
    studentId: String,
    onBack: () -> Unit
) {
    val selectedStudent by viewModel.selectedStudent.collectAsState()
    var showAddDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(selectedStudent?.name ?: "Grades") },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null) }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { showAddDialog = true }) {
                Icon(Icons.Default.Add, contentDescription = "Add grade")
            }
        }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp)) {
            selectedStudent?.let { student ->
                Text("Student: ${student.name}", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Text("GPA: ${student.gpa}", style = MaterialTheme.typography.bodyMedium)
                Spacer(modifier = Modifier.height(16.dp))
            }
            Text(
                "Grades are loaded from Supabase and cached locally via Room.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }

    if (showAddDialog) {
        AddGradeDialog(
            onDismiss = { showAddDialog = false },
            onConfirm = { courseId, value, type ->
                viewModel.saveGrade(
                    studentId = studentId,
                    courseId = courseId,
                    value = value,
                    type = type,
                    teacherId = "current-teacher-id"
                )
                showAddDialog = false
            }
        )
    }
}

@Composable
fun AddGradeDialog(
    onDismiss: () -> Unit,
    onConfirm: (courseId: String, value: Double, type: String) -> Unit
) {
    var courseId by remember { mutableStateOf("") }
    var gradeValue by remember { mutableStateOf("") }
    var gradeType by remember { mutableStateOf("exam") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Grade") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = courseId,
                    onValueChange = { courseId = it },
                    label = { Text("Course ID") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = gradeValue,
                    onValueChange = { gradeValue = it },
                    label = { Text("Grade (0-10)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Text("Type:", style = MaterialTheme.typography.labelMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("exam", "assignment", "project").forEach { type ->
                        FilterChip(
                            selected = gradeType == type,
                            onClick = { gradeType = type },
                            label = { Text(type.replaceFirstChar { it.uppercase() }) }
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val value = gradeValue.toDoubleOrNull() ?: 0.0
                    if (courseId.isNotBlank()) {
                        onConfirm(courseId, value, gradeType)
                    }
                }
            ) { Text("Save") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}
