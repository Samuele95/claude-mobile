package com.claudemobile.claude_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import es.antonborri.home_widget.HomeWidgetProvider

class QuickPromptWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = android.widget.RemoteViews(context.packageName, R.layout.quick_prompt_widget)

            val status = widgetData.getString("status", "idle")
            views.setTextViewText(
                R.id.widget_status,
                if (status == "running") "Processing..." else "Ready"
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
