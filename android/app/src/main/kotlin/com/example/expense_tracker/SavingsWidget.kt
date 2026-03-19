package com.example.expense_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.*

data class SavingsGoalData(
    val title:    String,
    val emoji:    String,
    val saved:    Double,
    val target:   Double,
    val deadline: String?,
    val currency: String
)

class SavingsWidget : AppWidgetProvider() {

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
            android.content.ComponentName(context, SavingsWidget::class.java)
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
                val goal  = readTopGoal(context)
                val views = RemoteViews(context.packageName, R.layout.widget_savings)

                // ── Background opacity (same prefs key as balance widget) ──────
                val prefs = context.getSharedPreferences(
                    "FlutterSharedPreferences", Context.MODE_PRIVATE)
                val opacity = try {
                    prefs.getLong("flutter.widget_opacity", 80L).toInt()
                } catch (e: Exception) {
                    try { prefs.getInt("flutter.widget_opacity", 80) }
                    catch (e2: Exception) { 80 }
                }
                val alpha   = (opacity.coerceIn(20, 100) / 100.0 * 255).toInt()
                val bgColor = (alpha shl 24) or 0x111111
                views.setInt(R.id.savings_widget_root, "setBackgroundColor", bgColor)

                // ── Tap → open app ────────────────────────────────────────────
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 1, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.savings_widget_root, pendingIntent)

                if (goal == null) {
                    // ── No goals: show placeholder ────────────────────────────
                    views.setViewVisibility(R.id.tv_goal_emoji,    View.INVISIBLE)
                    views.setViewVisibility(R.id.tv_goal_title,    View.INVISIBLE)
                    views.setViewVisibility(R.id.tv_goal_deadline, View.INVISIBLE)
                    views.setViewVisibility(R.id.tv_goal_pct,      View.INVISIBLE)
                    views.setViewVisibility(R.id.progress_fill,    View.INVISIBLE)
                    views.setViewVisibility(R.id.tv_saved,         View.INVISIBLE)
                    views.setViewVisibility(R.id.tv_target,        View.INVISIBLE)
                    views.setViewVisibility(R.id.tv_no_goals,      View.VISIBLE)
                } else {
                    // ── Show goal data ────────────────────────────────────────
                    views.setViewVisibility(R.id.tv_no_goals, View.GONE)

                    val pct = if (goal.target > 0)
                        (goal.saved / goal.target).coerceIn(0.0, 1.0)
                    else 0.0
                    val pctInt = (pct * 100).toInt()

                    views.setTextViewText(R.id.tv_goal_emoji,  goal.emoji)
                    views.setTextViewText(R.id.tv_goal_title,  goal.title)
                    views.setTextViewText(R.id.tv_goal_pct,    "$pctInt%")
                    views.setTextViewText(R.id.tv_saved,       fmt(goal.saved,   goal.currency))
                    views.setTextViewText(R.id.tv_target,      fmt(goal.target,  goal.currency))

                    // Deadline label
                    if (!goal.deadline.isNullOrBlank()) {
                        val daysLeft = daysUntil(goal.deadline)
                        val deadlineText = when {
                            daysLeft < 0  -> "Muddat o'tdi"
                            daysLeft == 0 -> "Bugun!"
                            daysLeft == 1 -> "1 kun qoldi"
                            else          -> "$daysLeft kun qoldi"
                        }
                        views.setTextViewText(R.id.tv_goal_deadline, deadlineText)
                        views.setViewVisibility(R.id.tv_goal_deadline, View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.tv_goal_deadline, View.GONE)
                    }

                    // ── Progress bar fill via scaleX trick ────────────────────
                    // RemoteViews can't set layout params directly, but we can
                    // use setFloat to call scaleX on the fill view.
                    // The fill view starts at 0dp width — we handle this with
                    // a fixed max-width fill view + scaleX from pivot=left.
                    views.setFloat(R.id.progress_fill, "setScaleX", pct.toFloat().coerceAtLeast(0.01f))

                    // Colour: green when done, amber in progress, red if overdue
                    val fillColor = when {
                        pct >= 1.0 -> 0xFF4CAF50.toInt()  // green — reached!
                        !goal.deadline.isNullOrBlank() && daysUntil(goal.deadline) < 0
                            -> 0xFFF44336.toInt()  // red — overdue
                        else       -> 0xFFFFD700.toInt()  // amber — in progress
                    }
                    views.setInt(R.id.progress_fill, "setBackgroundColor", fillColor)
                    views.setTextColor(R.id.tv_goal_pct, fillColor)
                }

                appWidgetManager.updateAppWidget(widgetId, views)

            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        // ── Read the top savings goal (most recently created) ─────────────────
        private fun readTopGoal(context: Context): SavingsGoalData? {
            val currency = try {
                context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    .getString("flutter.currency", "so'm") ?: "so'm"
            } catch (e: Exception) { "so'm" }

            return try {
                val dbFile = context.getDatabasePath("chontak.db")
                if (!dbFile.exists()) return null

                val db = SQLiteDatabase.openDatabase(
                    dbFile.path, null, SQLiteDatabase.OPEN_READONLY)

                // Pick the goal with the highest progress percentage first,
                // falling back to most recently created — shows the most
                // relevant goal prominently on the home screen.
                val cursor = db.rawQuery(
                    """SELECT title, emoji, saved, target, deadline
                       FROM savings
                       WHERE target > 0
                       ORDER BY (saved * 1.0 / target) DESC, created_at DESC
                       LIMIT 1""",
                    null
                )

                val result = if (cursor.moveToFirst()) {
                    SavingsGoalData(
                        title    = cursor.getString(0) ?: "Goal",
                        emoji    = cursor.getString(1) ?: "🎯",
                        saved    = cursor.getDouble(2),
                        target   = cursor.getDouble(3),
                        deadline = cursor.getString(4),
                        currency = currency
                    )
                } else null

                cursor.close()
                db.close()
                result

            } catch (e: Exception) {
                null
            }
        }

        // ── Days until a deadline string (ISO format YYYY-MM-DD) ──────────────
        private fun daysUntil(deadline: String): Int {
            return try {
                val sdf   = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                val target = sdf.parse(deadline) ?: return Int.MAX_VALUE
                val today  = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0);      set(Calendar.MILLISECOND, 0)
                }.time
                val diff = target.time - today.time
                (diff / (1000 * 60 * 60 * 24)).toInt()
            } catch (e: Exception) { Int.MAX_VALUE }
        }

        // ── Format currency amount ────────────────────────────────────────────
        private fun fmt(amount: Double, currency: String): String {
            val sign      = if (amount < 0) "-" else ""
            val abs       = Math.abs(amount)
            val formatted = String.format("%.0f", abs)
                .reversed().chunked(3).joinToString(".").reversed()
            return "$sign$currency $formatted"
        }
    }
}