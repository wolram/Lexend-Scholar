package com.marlow.lexendscholar.ui.adaptive

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.marlow.lexendscholar.data.Student

@Composable
fun TabletTwoPaneLayout(
    students: List<Student>,
    selectedStudent: Student?,
    onStudentSelect: (Student) -> Unit,
    detailContent: @Composable (Student) -> Unit
) {
    Row(modifier = Modifier.fillMaxSize()) {
        // List pane (40% width)
        Box(modifier = Modifier.weight(0.4f).fillMaxHeight()) {
            StudentListForTablet(
                students = students,
                selectedId = selectedStudent?.id,
                onSelect = onStudentSelect
            )
        }
        VerticalDivider()
        // Detail pane (60% width)
        Box(modifier = Modifier.weight(0.6f).fillMaxHeight()) {
            if (selectedStudent != null) {
                detailContent(selectedStudent)
            } else {
                Box(modifier = Modifier.fillMaxSize()) {
                    Text(
                        text = "Selecione um aluno",
                        style = MaterialTheme.typography.bodyLarge,
                        modifier = Modifier.padding(24.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun StudentListForTablet(
    students: List<Student>,
    selectedId: String?,
    onSelect: (Student) -> Unit
) {
    // Highlighted list for tablet selection
}
