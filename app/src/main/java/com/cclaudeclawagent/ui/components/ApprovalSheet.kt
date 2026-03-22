package com.cclaudeclawagent.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.cclaudeclawagent.data.model.ApprovalUiModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ApprovalSheet(
    approval: ApprovalUiModel,
    onApproveOnce: () -> Unit,
    onApproveStage: () -> Unit,
    onReject: () -> Unit,
    onDismiss: () -> Unit,
) {
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text("原子授权审批", style = MaterialTheme.typography.titleLarge)
            Text(approval.summary, style = MaterialTheme.typography.bodyLarge)
            Text("Risk: ${approval.riskLevel}")
            Text("Rollback: ${if (approval.reversible) "available" else "not guaranteed"}")
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(approval.operations) { op ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(op.type, style = MaterialTheme.typography.titleMedium)
                            Text(op.target, style = MaterialTheme.typography.bodyMedium)
                            Text(op.preview, style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }
            }
            Button(onClick = onApproveOnce, modifier = Modifier.fillMaxWidth()) {
                Text("允许一次")
            }
            OutlinedButton(onClick = onApproveStage, modifier = Modifier.fillMaxWidth()) {
                Text("允许本阶段")
            }
            OutlinedButton(onClick = onReject, modifier = Modifier.fillMaxWidth()) {
                Text("拒绝")
            }
        }
    }
}
