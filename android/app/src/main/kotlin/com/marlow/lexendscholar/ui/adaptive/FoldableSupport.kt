package com.marlow.lexendscholar.ui.adaptive

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.window.layout.FoldingFeature
import androidx.window.layout.WindowInfoTracker
import androidx.compose.ui.platform.LocalContext
import kotlinx.coroutines.flow.map

enum class DevicePosture {
    NormalPosture,
    BookPosture,
    SeparatingPosture
}

@Composable
fun calculateDevicePosture(): DevicePosture {
    val context = LocalContext.current
    val devicePosture by WindowInfoTracker
        .getOrCreate(context)
        .windowLayoutInfo(context as androidx.activity.ComponentActivity)
        .map { layoutInfo ->
            val foldingFeature = layoutInfo.displayFeatures
                .filterIsInstance<FoldingFeature>()
                .firstOrNull()
            when {
                foldingFeature?.isOccluding == true &&
                        foldingFeature.orientation == FoldingFeature.Orientation.VERTICAL ->
                    DevicePosture.BookPosture
                foldingFeature?.isSeparating == true ->
                    DevicePosture.SeparatingPosture
                else -> DevicePosture.NormalPosture
            }
        }
        .collectAsState(initial = DevicePosture.NormalPosture)

    return devicePosture
}

@Composable
fun FoldableAwareContent(
    normalContent: @Composable () -> Unit,
    bookContent: @Composable () -> Unit,
    separatingContent: @Composable () -> Unit
) {
    when (calculateDevicePosture()) {
        DevicePosture.BookPosture -> bookContent()
        DevicePosture.SeparatingPosture -> separatingContent()
        DevicePosture.NormalPosture -> normalContent()
    }
}
