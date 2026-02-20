package com.mrmoney.mrmoney

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.app.PendingIntent
import android.content.Intent

class HomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        android.util.Log.d("HomeWidgetProvider", "STANDARD onUpdate called for IDs: ${appWidgetIds.joinToString()}")
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        android.util.Log.d("HomeWidgetProvider", "CUSTOM onUpdate called for IDs: ${appWidgetIds.joinToString()}")
        
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                    val dailySpent = widgetData.getString("daily_spent", "0.00") ?: "0.00"
                    val dailyReceived = widgetData.getString("daily_received", "0.00") ?: "0.00"
                    val pendingCount = widgetData.getString("pending_count", "0") ?: "0"

                    android.util.Log.d("HomeWidgetProvider", "WidgetId: $widgetId, Spent: $dailySpent, Received: $dailyReceived, Pending: $pendingCount")

                    setTextViewText(R.id.daily_spent, "₹$dailySpent")
                    setTextViewText(R.id.daily_received, "₹$dailyReceived")
                    setTextViewText(R.id.pending_count, "$pendingCount")

                    // Open App on Click
                    val intent = Intent(context, MainActivity::class.java)
                    intent.action = Intent.ACTION_VIEW
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        0,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
                android.util.Log.d("HomeWidgetProvider", "Widget $widgetId updated successfully")
            } catch (e: Exception) {
                android.util.Log.e("HomeWidgetProvider", "Error updating widget", e)
            }
        }
    }
}
