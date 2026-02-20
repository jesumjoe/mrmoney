package com.mrmoney.mrmoney

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.app.PendingIntent
import android.content.Intent

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val dailySpent = try {
                    widgetData.getFloat("daily_spent", 0.0f)
                } catch (e: Exception) {
                    try {
                        widgetData.getLong("daily_spent", 0L).toFloat()
                    } catch (e: Exception) {
                        0.0f
                    }
                }
                
                val dailyReceived = try {
                    widgetData.getFloat("daily_received", 0.0f)
                } catch (e: Exception) {
                    try {
                        widgetData.getLong("daily_received", 0L).toFloat()
                    } catch (e: Exception) {
                        0.0f
                    }
                }
                val pendingCount = widgetData.getInt("pending_count", 0)

                setTextViewText(R.id.daily_spent, "₹${String.format("%.2f", dailySpent)}")
                setTextViewText(R.id.daily_received, "₹${String.format("%.2f", dailyReceived)}")
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
        }
    }
}
