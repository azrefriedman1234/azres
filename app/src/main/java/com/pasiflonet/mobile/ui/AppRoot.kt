package com.pasiflonet.mobile.ui

import androidx.compose.runtime.*

@Composable
fun AppRoot() {
  var screen by remember { mutableStateOf("login") }

  when (screen) {
    "login" -> LoginScreen(onLoggedIn = { screen = "main" })
    "main" -> MainScreen(onOpenDetails = { screen = "details" })
    "details" -> DetailsScreen(onClose = { screen = "main" })
  }
}
