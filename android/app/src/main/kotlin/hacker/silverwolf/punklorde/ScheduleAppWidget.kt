package hacker.silverwolf.punklorde

import android.content.Context
import android.content.ComponentName
import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.PixelFormat
import android.graphics.drawable.Drawable
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.action.clickable
import androidx.glance.action.actionStartActivity
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

class ScheduleAppWidget : GlanceAppWidget() {

    // 只要这个方法被调用，里面的 UI 就会从头重新构建，读取最新的 SP 数据
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = LocalContext.current.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

            val hasEvent = prefs.getString("has_event", "false") == "true"
            val title = prefs.getString("event_title", "暂无课程") ?: "暂无课程"
            val location = prefs.getString("event_location", "") ?: ""
            val time = prefs.getString("event_time", "") ?: ""
            val endTime = prefs.getString("event_end_time", "") ?: ""
            val week = prefs.getString("event_week", "") ?: ""
            val day = prefs.getString("event_day", "") ?: ""
            val status = prefs.getString("event_status", "") ?: ""
            val colorHex = prefs.getString("event_color", "FF6200EE") ?: "FF6200EE"

            val fullTime = if (endTime.isNullOrEmpty()) time else "$time - $endTime"
            val tagColor = parseColorHex(colorHex)

            GlanceTheme {
                Box(
                    modifier = GlanceModifier.fillMaxSize(),
                    contentAlignment = Alignment.BottomCenter
                ) {
                    
                    Image(
                        provider = ImageProvider(R.drawable.widget_bg),
                        contentDescription = null,
                        modifier = GlanceModifier.fillMaxSize(),
                        contentScale = ContentScale.Crop 
                    )

                    // 第二层 Box：负责文字内容的排版
                    Box(
                        modifier = GlanceModifier
                            .fillMaxSize()
                            .padding(16.dp)
                            .clickable(
                                actionStartActivity(
                                    ComponentName(
                                        LocalContext.current.packageName,
                                        "hacker.silverwolf.punklorde.MainActivity"
                                    )
                                )
                            )
                    ) {
                        if (hasEvent) {
                            EventView(
                                title = title,
                                location = location,
                                fullTime = fullTime,
                                week = week,
                                day = day,
                                status = status,
                                tagColor = tagColor,
                            )
                        } else {
                            EmptyView()
                        }
                    }
                }
            }

        }
    }

    @Composable
    private fun EventView(
        title: String, location: String, fullTime: String,
        week: String, day: String, status: String, tagColor: Color,
    ) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.Start,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "$week $day",
                    style = TextStyle(color = ColorProvider(Color.White), fontSize = 14.sp)
                )
                Spacer(modifier = GlanceModifier.defaultWeight())
                StatusBadge(status = status)
            }

            Spacer(modifier = GlanceModifier.height(12.dp))

            Row(verticalAlignment = Alignment.Top) {
                Box(
                    modifier = GlanceModifier
                        .width(4.dp)
                        .height(24.dp)
                        .background(tagColor)
                ) {}
                Spacer(modifier = GlanceModifier.width(12.dp))
                Text(
                    text = title,
                    style = TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    ),
                    modifier = GlanceModifier.defaultWeight()
                )
            }

            Spacer(modifier = GlanceModifier.height(10.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                androidx.glance.Image(
                    provider = ImageProvider(R.drawable.ic_time),
                    contentDescription = null,
                    modifier = GlanceModifier.width(16.dp).height(16.dp)
                )
                Spacer(modifier = GlanceModifier.width(6.dp))
                Text(
                    text = fullTime, 
                    style = TextStyle(color = ColorProvider(Color(0xFFE0E0E0)), fontSize = 16.sp)
                )
            }

            if (!location.isNullOrEmpty()) {
                Spacer(modifier = GlanceModifier.height(6.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    androidx.glance.Image(
                        provider = ImageProvider(R.drawable.ic_location),
                        contentDescription = null,
                        modifier = GlanceModifier.width(16.dp).height(16.dp)
                    )
                    Spacer(modifier = GlanceModifier.width(6.dp))
                    Text(
                        text = location, 
                        style = TextStyle(color = ColorProvider(Color(0xFFE0E0E0)), fontSize = 16.sp)
                    )
                }
            }
        }
    }

    @Composable
    private fun StatusBadge(status: String) {
        val isOngoing = status == "ongoing"
        val text = if (isOngoing) "进行中" else "即将开始"
        val textColor = if (isOngoing) Color.White else Color(0xFFEEEEEE)

        Box(
            modifier = GlanceModifier
                .background(ImageProvider(if (isOngoing) R.drawable.bg_status_ongoing else R.drawable.bg_status_upcoming))
                .padding(horizontal = 10.dp, vertical = 3.dp)
        ) {
            Text(
                text = text,
                style = TextStyle(color = ColorProvider(textColor), fontSize = 11.sp, fontWeight = FontWeight.Medium)
            )
        }
    }


    @Composable
    private fun EmptyView() {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // 加载占位图标
            androidx.glance.Image(
                provider = ImageProvider(R.drawable.ic_empty),
                contentDescription = null,
                modifier = GlanceModifier.width(48.dp).height(48.dp)
            )
            Spacer(modifier = GlanceModifier.height(8.dp))
            Text(text = "暂无课程", style = TextStyle(color = ColorProvider(Color(0xAAFFFFFF)), fontSize = 14.sp))
        }
    }
}

fun parseColorHex(colorHex: String): Color {
    return try {
        val cleaned = colorHex.removePrefix("#")
        val argb = if (cleaned.length == 6) "FF$cleaned" else cleaned
        Color(argb.toLong(16).toInt())
    } catch (e: Exception) {
        Color(0xFF6200EE)
    }
}
