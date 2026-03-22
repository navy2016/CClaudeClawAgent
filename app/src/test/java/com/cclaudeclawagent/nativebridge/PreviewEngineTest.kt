package com.cclaudeclawagent.nativebridge

import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PreviewEngineTest {
    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun writePromptProducesPendingApproval() {
        val engine = PreviewEngine()
        val snapshot = json.decodeFromString<NativeSnapshot>(engine.send("请修改 main.py 并写入修复"))
        assertNotNull(snapshot.pendingApproval)
        assertEquals("MODERATE", snapshot.pendingApproval?.riskLevel)
        assertTrue(snapshot.assistantReply.contains("原子批次"))
    }
}
