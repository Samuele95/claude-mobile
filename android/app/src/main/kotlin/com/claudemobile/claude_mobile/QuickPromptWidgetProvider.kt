package com.claudemobile.claude_mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class QuickPromptWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.quick_prompt_widget)

            val status = widgetData.getString("status", "idle")
            views.setTextViewText(
                R.id.widget_status,
                if (status == "running") "Processing..." else "Ready"
            )

            // Open the app when the prompt button is tapped
            val intent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("claudecarry://prompt")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                widgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_prompt_button, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
