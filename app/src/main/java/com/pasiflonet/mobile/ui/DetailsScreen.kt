package com.pasiflonet.mobile.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun DetailsScreen(onClose: () -> Unit) {
  var text by remember { mutableStateOf("") }
  var translated by remember { mutableStateOf("") }
  var withMedia by remember { mutableStateOf(true) }

  Column(Modifier.fillMaxSize().padding(12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
    Text("פרטים", style = MaterialTheme.typography.headlineSmall)

    OutlinedTextField(text, { text = it }, label = { Text("טקסט הודעה (ניתן לעריכה)") }, modifier = Modifier.fillMaxWidth())
    OutlinedTextField(translated, { translated = it }, label = { Text("תרגום אוטומטי (חינם ללא API) - TODO") }, modifier = Modifier.fillMaxWidth())

    Text("מדיה ממוזערת + נקודת Watermark + Blur בטאץ' - TODO")

    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
      FilterChip(selected = withMedia, onClick = { withMedia = true }, label = { Text("שלח עם מדיה") })
      FilterChip(selected = !withMedia, onClick = { withMedia = false }, label = { Text("שלח בלי מדיה") })
    }

    Button(onClick = {
      // TODO: להפעיל WorkManager ברקע: הורדה+עיבוד+שליחה לערוץ יעד מוגדר
      onClose()
    }) { Text("שלח הודעה") }
  }
}
