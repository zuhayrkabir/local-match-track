package live.ditto.flutter

import android.content.Context
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import com.ditto.internal.transports.DittoSyncPermissions

class DittoPlugin : FlutterPlugin, MethodCallHandler {

    private var flutterApi: FlutterDittoApi? = null

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var syncPermissions: DittoSyncPermissions? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "ditto_plugin")
        channel.setMethodCallHandler(this)

        context = binding.applicationContext
        flutterApi = FlutterDittoApi(binding.binaryMessenger)
        syncPermissions = DittoSyncPermissions(context)

        // Automatically set Android context to match Kotlin's automatic initialization
        // This eliminates the need for Dart code to call setAndroidContext via method channel
        com.ditto.dittoffi.dittoffi_set_android_context(context)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterApi = null
        syncPermissions = null
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "getAndroidContext") {
            result.success(context)
        } else if (call.method == "setAndroidContext") {
            assert(Looper.myLooper() == Looper.getMainLooper()) { "Calling setAndroidContext must be done from main thread!" }

            com.ditto.dittoffi.dittoffi_set_android_context(context)
            result.success("")
        } else if (call.method == "getRequiredPermissions") {
            val permissions = syncPermissions?.requiredPermissions() ?: emptyList()
            result.success(permissions)
        } else if (call.method == "getMissingPermissions") {
            val permissionsList = call.argument<List<String>>("permissions")
            val permissions = if (permissionsList != null) {
                syncPermissions?.missingPermissions(permissionsList) ?: emptyArray()
            } else {
                syncPermissions?.missingPermissions() ?: emptyArray()
            }
            result.success(permissions.toList())
        } else {
            result.notImplemented()
        }
    }
}
