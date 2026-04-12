package com.lexendscholar.app.ui.adaptive

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.window.layout.FoldingFeature
import androidx.window.layout.WindowInfoTracker
import androidx.window.layout.WindowLayoutInfo
import kotlinx.coroutines.flow.collectLatest

/**
 * LS-159: Foldable device support using WindowInfoTracker.
 * Detects fold state (tabletop, book mode) and adapts the layout accordingly.
 */

enum class FoldState {
    Normal,
    Tabletop,  // fold is horizontal (half-open like a laptop)
    Book       // fold is vertical (book-style)
}

@Composable
fun rememberFoldState(): State<FoldState> {
    val context = LocalContext.current
    val foldState = remember { mutableStateOf(FoldState.Normal) }

    LaunchedEffect(Unit) {
        WindowInfoTracker.getOrCreate(context)
            .windowLayoutInfo(context as androidx.activity.ComponentActivity)
            .collectLatest { layoutInfo ->
                foldState.value = layoutInfo.toFoldState()
            }
    }

    return foldState
}

private fun WindowLayoutInfo.toFoldState(): FoldState {
    val foldingFeature = displayFeatures.filterIsInstance<FoldingFeature>().firstOrNull()
        ?: return FoldState.Normal

    return when {
        foldingFeature.state == FoldingFeature.State.HALF_OPENED &&
            foldingFeature.orientation == FoldingFeature.Orientation.HORIZONTAL -> FoldState.Tabletop
        foldingFeature.state == FoldingFeature.State.HALF_OPENED &&
            foldingFeature.orientation == FoldingFeature.Orientation.VERTICAL -> FoldState.Book
        else -> FoldState.Normal
    }
}

/**
 * Layout wrapper that adapts to foldable device postures.
 *
 * - Tabletop: content splits into top/bottom at the hinge (media on top, controls on bottom)
 * - Book: content splits into left/right at the hinge
 * - Normal: standard single-pane layout
 */
@Composable
fun FoldableAwareLayout(
    foldState: FoldState,
    normalContent: @Composable () -> Unit,
    tabletopTop: @Composable () -> Unit = normalContent,
    tabletopBottom: @Composable () -> Unit = {},
    bookLeft: @Composable () -> Unit = normalContent,
    bookRight: @Composable () -> Unit = {}
) {
    when (foldState) {
        FoldState.Tabletop -> {
            Column(modifier = Modifier.fillMaxSize()) {
                Box(modifier = Modifier.weight(1f)) { tabletopTop() }
                HorizontalDivider(thickness = 2.dp)
                Box(modifier = Modifier.weight(1f)) { tabletopBottom() }
            }
        }
        FoldState.Book -> {
            Row(modifier = Modifier.fillMaxSize()) {
                Box(modifier = Modifier.weight(1f)) { bookLeft() }
                VerticalDivider(thickness = 2.dp)
                Box(modifier = Modifier.weight(1f)) { bookRight() }
            }
        }
        FoldState.Normal -> normalContent()
    }
}

// LS-159: Galaxy Z Fold support — WindowInfoTracker detects FoldingFeature state and orientation.
// Tabletop posture: content splits at horizontal hinge (top=content, bottom=controls).
// Book posture: content splits at vertical hinge (left=list, right=detail).
// App does not crash on foldables — gracefully degrades to FoldState.Normal when no hinge detected.
