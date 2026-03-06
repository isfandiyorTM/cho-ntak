package com.example.expense_tracker

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

// Called by Flutter via MethodChannel whenever a transaction is saved/deleted
// Also triggered on screen unlock (so widget always stays fresh)
class WidgetUpdateReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != ACTION_UPDATE_WIDGET &&
            action != Intent.ACTION_USER_PRESENT &&
            action != Intent.ACTION_BOOT_COMPLETED) return

        refreshAllWidgets(context)
    }

    companion object {
        const val ACTION_UPDATE_WIDGET = "com.example.expense_tracker.UPDATE_WIDGET"

        fun refreshAllWidgets(context: Context) {
            val manager    = AppWidgetManager.getInstance(context)
            val component  = ComponentName(context, BalanceWidget::class.java)
            val widgetIds  = manager.getAppWidgetIds(component)
            for (id in widgetIds) {
                BalanceWidget.updateWidget(context, manager, id)
            }
        }
    }
}