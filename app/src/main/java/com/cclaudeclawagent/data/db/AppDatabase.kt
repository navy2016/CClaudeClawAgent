package com.cclaudeclawagent.data.db

import androidx.room.Database
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.RoomDatabase

@Entity(tableName = "conversations")
data class ConversationEntity(
    @PrimaryKey val id: String,
    val title: String,
    val mode: String,
    val updatedAtMillis: Long,
)

@Entity(tableName = "messages")
data class MessageEntity(
    @PrimaryKey val id: String,
    val conversationId: String,
    val role: String,
    val payloadJson: String,
    val createdAtMillis: Long,
)

@Entity(tableName = "operation_batches")
data class OperationBatchEntity(
    @PrimaryKey val id: String,
    val conversationId: String,
    val status: String,
    val summary: String,
    val reversible: Boolean,
    val createdAtMillis: Long,
)

@Entity(tableName = "workflow_runs")
data class WorkflowRunEntity(
    @PrimaryKey val id: String,
    val conversationId: String,
    val workflowType: String,
    val state: String,
    val currentStage: String,
)

@Database(
    entities = [
        ConversationEntity::class,
        MessageEntity::class,
        OperationBatchEntity::class,
        WorkflowRunEntity::class,
    ],
    version = 1,
    exportSchema = true,
)
abstract class AppDatabase : RoomDatabase()
