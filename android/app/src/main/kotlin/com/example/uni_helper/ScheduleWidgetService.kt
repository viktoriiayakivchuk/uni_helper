package com.example.uni_helper

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

class ScheduleWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ScheduleRemoteViewsFactory(applicationContext)
    }
}

class ScheduleRemoteViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private data class LessonItem(
        val title: String,
        val startTime: String,
        val endTime: String,
        val type: String
    )

    private var lessons = mutableListOf<LessonItem>()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        lessons.clear()
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("schedule_json", "[]") ?: "[]"
        try {
            val jsonArray = JSONArray(jsonStr)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                lessons.add(
                    LessonItem(
                        title = obj.optString("title", ""),
                        startTime = obj.optString("startTime", ""),
                        endTime = obj.optString("endTime", ""),
                        type = obj.optString("type", "")
                    )
                )
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        lessons.clear()
    }

    override fun getCount(): Int = lessons.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_lesson_item)
        if (position >= lessons.size) return views

        val lesson = lessons[position]

        views.setTextViewText(R.id.lesson_title, lesson.title)
        views.setTextViewText(R.id.lesson_time, "${lesson.startTime} – ${lesson.endTime}")

        // Type badge text
        val typeText = when (lesson.type) {
            "lecture" -> "Лекція"
            "practice" -> "Практика"
            "lab" -> "Лаб"
            "exam" -> "Іспит"
            else -> ""
        }
        views.setTextViewText(R.id.lesson_type_badge, typeText)

        // Color bar based on type
        val barDrawable = when (lesson.type) {
            "lecture" -> R.drawable.lesson_bar_lecture
            "practice" -> R.drawable.lesson_bar_practice
            "lab" -> R.drawable.lesson_bar_lab
            "exam" -> R.drawable.lesson_bar_exam
            else -> R.drawable.lesson_bar_default
        }
        views.setInt(R.id.lesson_color_bar, "setBackgroundResource", barDrawable)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
