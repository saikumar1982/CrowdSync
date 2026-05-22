package com.crowdsync.app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var nativeModule: CrowdSyncNativeModule? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nativeModule = CrowdSyncNativeModule(this).also {
            it.install(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun onDestroy() {
        nativeModule?.dispose()
        nativeModule = null
        super.onDestroy()
    }
}
