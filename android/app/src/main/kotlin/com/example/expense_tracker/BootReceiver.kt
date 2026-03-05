package com.example.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            // Re-schedule the daily notification after reboot
            val rescheduleIntent = Intent(context, MainActivity::class.java)
            rescheduleIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            rescheduleIntent.putExtra("reschedule_notifications", true)
            context.startActivity(rescheduleIntent)
        }
    }
}