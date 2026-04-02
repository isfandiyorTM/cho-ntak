package com.example.expense_tracker

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.expense_tracker/widget"

    // Store the pending widget action — may arrive before Flutter engine is ready
    private var pendingWidgetAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Capture widget action from the launch intent
        pendingWidgetAction = intent?.getStringExtra(
            BalanceWidget.EXTRA_WIDGET_ACTION)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // App already running — deliver immediately via channel
        val action = intent.getStringExtra(BalanceWidget.EXTRA_WIDGET_ACTION)
        if (action != null) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL)
                    .invokeMethod("openAddTransaction", action)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    // Broadcast to WidgetUpdateReceiver
                    val intent = Intent(WidgetUpdateReceiver.ACTION_UPDATE_WIDGET)
                    intent.setPackage(packageName)
                    sendBroadcast(intent)
                    result.success(null)
                }
                "getWidgetAction" -> {
                    // Flutter asks on startup: was I opened from a widget button?
                    result.success(pendingWidgetAction)
                    pendingWidgetAction = null   // consume once
                }
                else -> result.notImplemented()
            }
        }
    }
}