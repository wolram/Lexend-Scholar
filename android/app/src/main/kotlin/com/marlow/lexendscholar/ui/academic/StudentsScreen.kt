package com.marlow.lexendscholar.ui.academic

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.marlow.lexendscholar.data.Student

@Composable
fun StudentsScreen(students: List<Student>) {
    LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        items(students) { student ->
            Card(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(student.name, style = MaterialTheme.typography.titleMedium)
                    Text("Matrícula: ${student.enrollment}", style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
    }
}
