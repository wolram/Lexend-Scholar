package com.lexendscholar.app.ui.academic

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.lexendscholar.app.data.model.Student
import com.lexendscholar.app.viewmodel.AcademicViewModel

enum class AttendanceStatus { Present, Late, Absent }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AttendanceScreen(
    viewModel: AcademicViewModel,
    classId: String,
    onBack: () -> Unit,
    onSave: () -> Unit
) {
    val students by viewModel.students.collectAsState()
    val attendanceMap = remember { mutableStateMapOf<String, AttendanceStatus>().apply {
        students.forEach { put(it.id, AttendanceStatus.Present) }
    }}

    LaunchedEffect(students) {
        students.forEach { student ->
            if (!attendanceMap.containsKey(student.id)) {
                attendanceMap[student.id] = AttendanceStatus.Present
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Attendance") },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null) }
                },
                actions = {
                    TextButton(onClick = {
                        val teacherId = "current-teacher-id"
                        students.forEach { student ->
                            val status = attendanceMap[student.id] ?: AttendanceStatus.Present
                            viewModel.saveAttendanceRecord(
                                studentId = student.id,
                                classId = classId,
                                status = status.name.lowercase(),
                                teacherId = teacherId
                            )
                        }
                        onSave()
                    }) {
                        Text("Save")
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(modifier = Modifier.fillMaxSize().padding(padding)) {
            items(students, key = { it.id }) { student ->
                AttendanceStudentRow(
                    student = student,
                    status = attendanceMap[student.id] ?: AttendanceStatus.Present,
                    onStatusChange = { newStatus -> attendanceMap[student.id] = newStatus }
                )
            }
        }
    }
}

@Composable
fun AttendanceStudentRow(
    student: Student,
    status: AttendanceStatus,
    onStatusChange: (AttendanceStatus) -> Unit
) {
    ListItem(
        headlineContent = { Text(student.name, fontWeight = FontWeight.Medium) },
        supportingContent = { Text(student.grade) },
        trailingContent = {
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                AttendanceStatus.entries.forEach { s ->
                    FilterChip(
                        selected = status == s,
                        onClick = { onStatusChange(s) },
                        label = { Text(s.name, style = MaterialTheme.typography.labelSmall) }
                    )
                }
            }
        }
    )
    HorizontalDivider()
}
