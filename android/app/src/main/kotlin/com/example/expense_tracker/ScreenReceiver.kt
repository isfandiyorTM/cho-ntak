package com.example.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationCompat
import android.database.sqlite.SQLiteDatabase
import java.util.*

class ScreenReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // ACTION_USER_PRESENT = phone unlocked (after PIN/pattern/fingerprint)
        if (intent.action != Intent.ACTION_USER_PRESENT) return

        val balance  = getBalanceFromDb(context)
        val currency = getCurrency(context)
        showNotification(context, balance, currency)
    }

    private fun getBalanceFromDb(context: Context): Double {
        return try {
            val dbPath = context.getDatabasePath("chontak.db")
            if (!dbPath.exists()) return 0.0

            val db = SQLiteDatabase.openDatabase(
                dbPath.path, null, SQLiteDatabase.OPEN_READONLY)

            val now    = Calendar.getInstance()
            val month  = String.format("%02d", now.get(Calendar.MONTH) + 1)
            val year   = now.get(Calendar.YEAR).toString()
            val cutoff = "$year-$month-01"

            // Income this month
            val ic = db.rawQuery(
                "SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='income' AND strftime('%m',date)=? AND strftime('%Y',date)=?",
                arrayOf(month, year))
            var income = 0.0
            if (ic.moveToFirst()) income = ic.getDouble(0)
            ic.close()

            // Expense this month
            val ec = db.rawQuery(
                "SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='expense' AND strftime('%m',date)=? AND strftime('%Y',date)=?",
                arrayOf(month, year))
            var expense = 0.0
            if (ec.moveToFirst()) expense = ec.getDouble(0)
            ec.close()

            // Carryover from all previous months
            val cc = db.rawQuery(
                "SELECT COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE 0 END),0) - COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END),0) FROM transactions WHERE date<?",
                arrayOf(cutoff))
            var carryover = 0.0
            if (cc.moveToFirst()) carryover = cc.getDouble(0)
            cc.close()

            db.close()
            carryover + income - expense
        } catch (e: Exception) { 0.0 }
    }

    private fun getCurrency(context: Context): String {
        return try {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.getString("flutter.currency", "so'm") ?: "so'm"
        } catch (e: Exception) { "so'm" }
    }

    private fun showNotification(context: Context, balance: Double, currency: String) {
        val channelId = "chontak_screen_channel"
        val manager   = context.getSystemService(
            Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId, "Cho'ntak Balans",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                setSound(null, null)
                enableVibration(false)
            }
            manager.createNotificationChannel(channel)
        }

        val sign   = if (balance < 0) "-" else ""
        val emoji  = if (balance < 0) "📉" else if (balance == 0.0) "😐" else "👛"
        val title  = "$emoji Cho'ntagingizda: $sign${fmt(balance.let { Math.abs(it) }, currency)}"
        val body   = message(balance)

        val notif = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setColor(0xFFFFD700.toInt())
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setSound(null)
            .build()

        manager.notify(2001, notif)
    }

    private fun message(balance: Double): String = when {
        balance < 0    -> "Balansingiz manfiy! Xarajatlarni kamaytiring."
        balance == 0.0 -> "Balansingiz nol. Daromad kiriting."
        balance < 50000 -> "Tejamkor bo'ling! Cho'ntagingiz ozayib qoldi."
        else           -> "Bugun ham tejamkor bo'ling! Har bir so'm muhim."
    }

    private fun fmt(amount: Double, currency: String): String = when {
        amount >= 1_000_000 -> "$currency ${String.format("%.1f", amount/1_000_000)}M"
        amount >= 1_000     -> "$currency ${String.format("%.0f", amount/1_000)}K"
        else                -> "$currency ${String.format("%.0f", amount)}"
    }
}