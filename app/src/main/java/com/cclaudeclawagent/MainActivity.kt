package com.cclaudeclawagent

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.remember
import com.cclaudeclawagent.nativebridge.NativeSession
import com.cclaudeclawagent.ui.chat.ChatScreen
import com.cclaudeclawagent.ui.chat.ChatViewModel
import com.cclaudeclawagent.ui.theme.CClaudeClawTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            CClaudeClawTheme {
                val session = remember { NativeSession(applicationContext.filesDir.absolutePath) }
                val viewModel = remember { ChatViewModel(session) }
                ChatScreen(viewModel = viewModel)
            }
        }
    }
}
