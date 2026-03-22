package com.cclaudeclawagent.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightColors = lightColorScheme(
    primary = Color(0xFF4A63FF),
    secondary = Color(0xFF7B61FF),
    tertiary = Color(0xFF11A683),
    surface = Color(0xFFF6F7FB),
    surfaceVariant = Color(0xFFE9ECF5),
    background = Color(0xFFFFFFFF),
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFF92A2FF),
    secondary = Color(0xFFB39DFF),
    tertiary = Color(0xFF6CE0C1),
    surface = Color(0xFF11131A),
    surfaceVariant = Color(0xFF222632),
    background = Color(0xFF090B10),
)

@Composable
fun CClaudeClawTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        content = content,
    )
}
