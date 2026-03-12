package com.example.uni_helper

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ScheduleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: android.content.SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val lessonCount = widgetData.getInt("lesson_count", -1)

            if (lessonCount == 0) {
                // No lessons — show empty message
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                views.setViewVisibility(R.id.widget_list, View.GONE)
            } else {
                // Has lessons — show list
                views.setViewVisibility(R.id.widget_empty, View.GONE)
                views.setViewVisibility(R.id.widget_list, View.VISIBLE)

                val intent = Intent(context, ScheduleWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                views.setRemoteAdapter(R.id.widget_list, intent)
            }

            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}