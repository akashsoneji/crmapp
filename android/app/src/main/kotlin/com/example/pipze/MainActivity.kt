package com.example.pipze

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.webkit.WebView
import android.util.Log

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Disable WebView logging and frame rate logs
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
            WebView.setWebContentsDebuggingEnabled(false)
        }
        
        // Disable verbose logging for WebView components
        try {
            // Set log level to reduce noise
            System.setProperty("android.webkit.WebView.EnableSafeBrowsing", "false")
            System.setProperty("android.webkit.WebView.MetricsOptOut", "true")
            
            // Disable GPU logging
            System.setProperty("debug.egl.debug_messages", "0")
            System.setProperty("debug.gpu.debug_messages", "0")
            
        } catch (e: Exception) {
            Log.w("MainActivity", "Could not disable logging: ${e.message}")
        }
    }
}
