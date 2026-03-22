package com.cclaudeclawagent.nativebridge

import kotlinx.serialization.json.Json

class NativeSession(dataDir: String) {
    private val json = Json { ignoreUnknownKeys = true }
    private val handle: Long = runCatching { NativeBindings.sessionCreate(dataDir) }.getOrDefault(0L)
    private var fake = handle == 0L
    private val preview = PreviewEngine()

    fun send(text: String): NativeSnapshot = decode(
        if (fake) preview.send(text) else NativeBindings.sessionSendText(handle, text)
    )

    fun approve(batchId: String, scope: String): NativeSnapshot = decode(
        if (fake) preview.approve(batchId, scope) else NativeBindings.sessionApproveBatch(handle, batchId, scope)
    )

    fun reject(batchId: String, reason: String): NativeSnapshot = decode(
        if (fake) preview.reject(batchId, reason) else NativeBindings.sessionRejectBatch(handle, batchId, reason)
    )

    fun undo(): NativeSnapshot = decode(
        if (fake) preview.undo() else NativeBindings.sessionUndo(handle)
    )

    fun redo(): NativeSnapshot = decode(
        if (fake) preview.redo() else NativeBindings.sessionRedo(handle)
    )

    private fun decode(raw: String): NativeSnapshot = json.decodeFromString(raw)
}
