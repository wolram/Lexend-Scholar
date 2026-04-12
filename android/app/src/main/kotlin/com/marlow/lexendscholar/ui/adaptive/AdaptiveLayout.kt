package com.marlow.lexendscholar.ui.adaptive

import androidx.compose.material3.adaptive.ExperimentalMaterial3AdaptiveApi
import androidx.compose.material3.adaptive.layout.AnimatedPane
import androidx.compose.material3.adaptive.layout.ListDetailPaneScaffold
import androidx.compose.material3.adaptive.layout.ListDetailPaneScaffoldRole
import androidx.compose.material3.adaptive.navigation.rememberListDetailPaneScaffoldNavigator
import androidx.compose.runtime.Composable
import com.marlow.lexendscholar.data.Student

@OptIn(ExperimentalMaterial3AdaptiveApi::class)
@Composable
fun AdaptiveStudentLayout(
    students: List<Student>,
    onStudentSelect: (Student) -> Unit,
    detailContent: @Composable (Student?) -> Unit
) {
    val navigator = rememberListDetailPaneScaffoldNavigator<Student>()

    ListDetailPaneScaffold(
        directive = navigator.scaffoldDirective,
        value = navigator.scaffoldValue,
        listPane = {
            AnimatedPane {
                StudentListPane(
                    students = students,
                    onStudentClick = { student ->
                        navigator.navigateTo(ListDetailPaneScaffoldRole.Detail, student)
                        onStudentSelect(student)
                    }
                )
            }
        },
        detailPane = {
            AnimatedPane {
                detailContent(navigator.currentDestination?.content)
            }
        }
    )
}

@Composable
private fun StudentListPane(students: List<Student>, onStudentClick: (Student) -> Unit) {
    // List of students for the list pane
}
