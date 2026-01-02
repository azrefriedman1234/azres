package com.pasiflonet.mobile.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun LoginScreen(onLoggedIn: () -> Unit) {
  var apiId by remember { mutableStateOf("") }
  var apiHash by remember { mutableStateOf("") }
  var phone by remember { mutableStateOf("") }
  var code by remember { mutableStateOf("") }
  var pass by remember { mutableStateOf("") }
  var status by remember { mutableStateOf("הזן פרטים והתחבר") }

  Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
    Text("פסיפלונט מובייל", style = MaterialTheme.typography.headlineMedium)

    Button(onClick = { status = "TODO: בחירת סימן מים מהגלריה" }) {
      Text("ייבוא סימן מים ברירת מחדל מהגלריה")
    }

    OutlinedTextField(apiId, { apiId = it }, label = { Text("API ID") }, singleLine = true)
    OutlinedTextField(apiHash, { apiHash = it }, label = { Text("API HASH") }, singleLine = true)
    OutlinedTextField(phone, { phone = it }, label = { Text("מספר טלפון") }, singleLine = true)

    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
      Button(onClick = { status = "TODO: שליחת קוד אימות דרך TDLib" }) { Text("שלח קוד") }
      Button(onClick = { status = "TODO: אימות קוד/2FA ושמירת סשן"; onLoggedIn() }) { Text("התחברות") }
    }

    OutlinedTextField(code, { code = it }, label = { Text("קוד אימות") }, singleLine = true)
    OutlinedTextField(pass, { pass = it }, label = { Text("סיסמת 2FA (אם צריך)") }, singleLine = true)

    Text(status)
  }
}
