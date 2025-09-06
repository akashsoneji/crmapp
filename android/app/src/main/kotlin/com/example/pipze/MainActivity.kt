package com.example.pipze

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.webkit.WebView

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Disable WebView logging
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
            WebView.setWebContentsDebuggingEnabled(false)
        }
    }
}
