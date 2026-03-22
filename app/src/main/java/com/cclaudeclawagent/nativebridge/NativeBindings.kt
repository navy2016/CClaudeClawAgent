package com.cclaudeclawagent.nativebridge

internal object NativeBindings {
    init {
        runCatching { System.loadLibrary("cclaudeclaw") }
    }

    external fun sessionCreate(dataDir: String): Long
    external fun sessionDestroy(handle: Long)
    external fun sessionSendText(handle: Long, text: String): String
    external fun sessionApproveBatch(handle: Long, batchId: String, scope: String): String
    external fun sessionRejectBatch(handle: Long, batchId: String, reason: String): String
    external fun sessionUndo(handle: Long): String
    external fun sessionRedo(handle: Long): String
}
