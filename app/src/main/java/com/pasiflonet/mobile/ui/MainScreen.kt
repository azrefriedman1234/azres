package com.pasiflonet.mobile.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun MainScreen(onOpenDetails: () -> Unit) {
  // TODO: פה תתחבר ל-TDLib ותביא בלייב הודעות מכל הערוצים שהמשתמש מנוי אליהם.
  // דרישה: לשמור 100 הודעות, חדשות למעלה.

  Column(Modifier.fillMaxSize().padding(12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
    Text("פסיפלונט מובייל", style = MaterialTheme.typography.headlineSmall)

    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
      Button(onClick = { /* TODO: מחיקת קבצים זמניים */ }) { Text("מחיקת קבצים זמניים") }
      Button(onClick = { /* TODO: סגירת אפליקציה */ }) { Text("סגירת אפליקציה") }
    }

    LazyColumn(Modifier.fillMaxSize()) {
      items(20) { idx ->
        Card(Modifier.fillMaxWidth()) {
          Row(Modifier.fillMaxWidth().padding(10.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Column(Modifier.weight(1f)) {
              Text("טקסט הודעה לדוגמה #$idx")
              Text("תאריך+שעה: TODO", style = MaterialTheme.typography.labelSmall)
              Text("סוג/מדיה: TODO", style = MaterialTheme.typography.labelSmall)
              Text("תמונה ממוזערת: TODO", style = MaterialTheme.typography.labelSmall)
            }
            Button(onClick = onOpenDetails) { Text("פרטים") }
          }
        }
        Spacer(Modifier.height(8.dp))
      }
    }
  }
}
