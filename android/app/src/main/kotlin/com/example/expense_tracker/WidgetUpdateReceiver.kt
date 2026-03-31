package com.example.expense_tracker

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

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
            val manager = AppWidgetManager.getInstance(context)

            // Balance widget
            val balanceIds = manager.getAppWidgetIds(
                ComponentName(context, BalanceWidget::class.java))
            for (id in balanceIds) {
                BalanceWidget.updateWidget(context, manager, id)
            }

            // Savings widget
            val savingsIds = manager.getAppWidgetIds(
                ComponentName(context, SavingsWidget::class.java))
            for (id in savingsIds) {
                SavingsWidget.updateWidget(context, manager, id)
            }
        }
    }
}