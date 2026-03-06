package com.example.expense_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.*

data class WidgetData(
    val balance:  Double,
    val income:   Double,
    val expense:  Double,
    val currency: String
)

class BalanceWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            android.content.ComponentName(context, BalanceWidget::class.java)
        )
        for (id in ids) updateWidget(context, manager, id)
    }

    companion object {

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            try {
                val data  = readBalanceData(context)
                val views = RemoteViews(context.packageName, R.layout.widget_balance)

                // ── Opacity: Flutter stores SharedPreferences as Long ──
                val prefs  = context.getSharedPreferences(
                    "FlutterSharedPreferences", Context.MODE_PRIVATE)
                val opacity = try {
                    prefs.getLong("flutter.widget_opacity", 80L).toInt()
                } catch (e: Exception) {
                    try { prefs.getInt("flutter.widget_opacity", 80) }
                    catch (e2: Exception) { 80 }
                }
                val alpha   = (opacity.coerceIn(20, 100) / 100.0 * 255).toInt()
                val bgColor = (alpha shl 24) or 0x111111
                views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)

                // ── Balance ────────────────────────────────────────────
                val balanceColor = if (data.balance < 0) 0xFFF44336.toInt()
                else 0xFFFFFFFF.toInt()
                views.setTextViewText(R.id.tv_balance, fmt(data.balance, data.currency))
                views.setTextColor(R.id.tv_balance, balanceColor)

                // ── Income / Expense ───────────────────────────────────
                views.setTextViewText(R.id.tv_income,  fmt(data.income,  data.currency))
                views.setTextViewText(R.id.tv_expense, fmt(data.expense, data.currency))

                // ── Month ──────────────────────────────────────────────
                val monthName = SimpleDateFormat("MMMM yyyy", Locale.getDefault())
                    .format(Calendar.getInstance().time)
                views.setTextViewText(R.id.tv_month, monthName)

                // ── Tap → open app ─────────────────────────────────────
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                appWidgetManager.updateAppWidget(widgetId, views)

            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        private fun readBalanceData(context: Context): WidgetData {
            val currency = try {
                context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    .getString("flutter.currency", "so'm") ?: "so'm"
            } catch (e: Exception) { "so'm" }

            return try {
                val dbFile = context.getDatabasePath("chontak.db")
                if (!dbFile.exists()) return WidgetData(0.0, 0.0, 0.0, currency)

                val db = SQLiteDatabase.openDatabase(
                    dbFile.path, null, SQLiteDatabase.OPEN_READONLY)

                val cal    = Calendar.getInstance()
                val month  = String.format("%02d", cal.get(Calendar.MONTH) + 1)
                val year   = cal.get(Calendar.YEAR).toString()
                val cutoff = "$year-$month-01"

                val iCursor = db.rawQuery(
                    "SELECT COALESCE(SUM(amount),0) FROM transactions " +
                            "WHERE type='income' AND strftime('%m',date)=? AND strftime('%Y',date)=?",
                    arrayOf(month, year))
                val income = if (iCursor.moveToFirst()) iCursor.getDouble(0) else 0.0
                iCursor.close()

                val eCursor = db.rawQuery(
                    "SELECT COALESCE(SUM(amount),0) FROM transactions " +
                            "WHERE type='expense' AND strftime('%m',date)=? AND strftime('%Y',date)=?",
                    arrayOf(month, year))
                val expense = if (eCursor.moveToFirst()) eCursor.getDouble(0) else 0.0
                eCursor.close()

                val cCursor = db.rawQuery(
                    "SELECT COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE 0 END),0) - " +
                            "COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END),0) " +
                            "FROM transactions WHERE date < ?",
                    arrayOf(cutoff))
                val carryover = if (cCursor.moveToFirst()) cCursor.getDouble(0) else 0.0
                cCursor.close()

                db.close()
                WidgetData(carryover + income - expense, income, expense, currency)
            } catch (e: Exception) {
                WidgetData(0.0, 0.0, 0.0, currency)
            }
        }

        private fun fmt(amount: Double, currency: String): String {
            val sign = if (amount < 0) "-" else ""
            val abs  = Math.abs(amount)
            val formatted = String.format("%.0f", abs)
                .reversed()
                .chunked(3)
                .joinToString(".")
                .reversed()
            return "$sign$currency $formatted"
        }
    }
}