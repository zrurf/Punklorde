package hacker.silverwolf.punklorde

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

class MainActivity: FlutterActivity() {
    private val CHANNEL = "hacker.silverwolf.punklorde/widget_refresh"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "forceRefresh") {
                MainScope().launch {
                    try {
                        ScheduleAppWidget().updateAll(applicationContext)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("REFRESH_ERROR", e.message, null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
