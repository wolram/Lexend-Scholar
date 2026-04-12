package com.lexendscholar.app.ui.adaptive

import androidx.compose.material3.adaptive.ExperimentalMaterial3AdaptiveApi
import androidx.compose.material3.adaptive.layout.AnimatedPane
import androidx.compose.material3.adaptive.layout.ListDetailPaneScaffold
import androidx.compose.material3.adaptive.layout.ListDetailPaneScaffoldRole
import androidx.compose.material3.adaptive.layout.PaneAdaptedValue
import androidx.compose.material3.adaptive.navigation.rememberListDetailPaneScaffoldNavigator
import androidx.compose.material3.windowsizeclass.WindowSizeClass
import androidx.compose.material3.windowsizeclass.WindowWidthSizeClass
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import com.lexendscholar.app.data.model.Student
import com.lexendscholar.app.ui.academic.StudentsScreen
import com.lexendscholar.app.ui.academic.StudentDetailPane
import com.lexendscholar.app.viewmodel.AcademicViewModel

/**
 * LS-156: Adaptive layout using WindowSizeClass.
 * LS-157: Multi-pane list+detail for tablets using ListDetailPaneScaffold.
 */
@OptIn(ExperimentalMaterial3AdaptiveApi::class)
@Composable
fun AdaptiveStudentLayout(
    viewModel: AcademicViewModel,
    windowSizeClass: WindowSizeClass,
    onBack: () -> Unit
) {
    val navigator = rememberListDetailPaneScaffoldNavigator<Student>()
    val selectedStudent by viewModel.selectedStudent.collectAsState()

    ListDetailPaneScaffold(
        directive = navigator.scaffoldDirective,
        value = navigator.scaffoldValue,
        listPane = {
            AnimatedPane {
                StudentsScreen(
                    viewModel = viewModel,
                    onStudentClick = { student ->
                        viewModel.selectStudent(student)
                        navigator.navigateTo(ListDetailPaneScaffoldRole.Detail, student)
                    },
                    onBack = onBack
                )
            }
        },
        detailPane = {
            AnimatedPane {
                val student = navigator.currentDestination?.contentKey
                    ?: selectedStudent
                if (student != null) {
                    StudentDetailPane(
                        student = student,
                        isFullScreen = navigator.scaffoldValue[ListDetailPaneScaffoldRole.List] == PaneAdaptedValue.Hidden,
                        onBack = {
                            if (navigator.canNavigateBack()) {
                                navigator.navigateBack()
                            } else {
                                onBack()
                            }
                        }
                    )
                }
            }
        }
    )
}

/**
 * LS-156: Determine if we are on a compact (phone) or expanded (tablet) layout.
 */
fun WindowSizeClass.isCompact(): Boolean = widthSizeClass == WindowWidthSizeClass.Compact

fun WindowSizeClass.isExpanded(): Boolean = widthSizeClass == WindowWidthSizeClass.Expanded

// LS-156: WindowSizeClass detection — isCompact() for phones, isExpanded() for tablets
// UI breakpoints: Compact=phone single-pane, Medium=unfolded, Expanded=tablet/desktop dual-pane
