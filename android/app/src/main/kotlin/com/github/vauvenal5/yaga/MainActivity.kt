package com.github.vauvenal5.yaga

import android.content.Intent
import android.net.Uri
import android.util.Log
import android.widget.Toast

import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.lang.IllegalArgumentException

class MainActivity: FlutterActivity() {
    private val INTENT_CHANNEL = "yaga.channel.intent";
    private val GET_INTENT_ACTION_METHOD = "getIntentAction";
    private val GET_INTENT_TYPE_METHOD = "getIntentType";
    private val GET_INTENT_SET_RESULT = "setSelectedFile";
    private val ATTACH_DATA = "attachData";

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        val intent = getIntent();

        //todo: check if granted
        //todo: check if Android verison is high enough
//        Intent(Settings.ACTION_REQUEST_MANAGE_MEDIA).apply {
//            data = Uri.parse("package:$packageName")
//            try {
//                startActivityForResult(this, 303)
//            } catch (e: Exception) {
//            }
//        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL).setMethodCallHandler {
                call, result ->
            if(call.method.contentEquals(GET_INTENT_ACTION_METHOD)) {
                result.success(intent.getAction());
            } else if (call.method.contentEquals(GET_INTENT_TYPE_METHOD)) {
                result.success(intent.getType());
            } else if (call.method.contentEquals(GET_INTENT_SET_RESULT)) {
                handleShareSelectedImageIntent(call, result)
            } else if (call.method.contentEquals(ATTACH_DATA)) {
                attachData(call, result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun attachData(call: MethodCall, resultChannel: MethodChannel.Result) {
        val resultIntent = prepIntent(call, resultChannel)
        resultIntent.setAction(Intent.ACTION_ATTACH_DATA)
        this.startActivity(Intent.createChooser(resultIntent, "Use picture as..."))
        resultChannel.success(null)
    }

    private fun handleShareSelectedImageIntent(call: MethodCall, resultChannel: MethodChannel.Result) {
        val resultIntent = prepIntent(call, resultChannel)
        setResult(RESULT_OK, resultIntent)
        resultChannel.success(true)
        finish()
    }

    private fun prepIntent(call: MethodCall, resultChannel: MethodChannel.Result): Intent {
        val resultIntent = Intent();
        val path = call.argument<String>("path");
        val mime = call.argument<String>("mime");

        if(path == null || mime == null) {
            shareSelectedImageFailed(resultIntent, resultChannel)
        }

        val fileUri: Uri? = try {
            FileProvider.getUriForFile(
                this,
                this.packageName + ".fileprovider",
                File(path!!)
            )
        } catch (e: IllegalArgumentException) {
            Log.e("File Provider", "Could not retrieve content url for file.", e)
            null
        }

        if(fileUri == null) {
            shareSelectedImageFailed(resultIntent, resultChannel)
        }

        resultIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        resultIntent.setDataAndType(fileUri, mime)
        return resultIntent;
    }

    private fun shareSelectedImageFailed(resultIntent: Intent, resultChannel: MethodChannel.Result) {
        Toast.makeText(activity, "Failed to share image.", Toast.LENGTH_SHORT).show()
        resultIntent.setDataAndType(null, "")
        setResult(RESULT_CANCELED, resultIntent)
        resultChannel.success(false)
        finish()
    }

    //todo: this code might solve the copy issue
//    private fun addItem(name: String, filePath: String, mime: String): Uri {
//        val collection = if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
////            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
//            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_INTERNAL)
//        } else {
//            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
//        }
//
//        var relativePath = filePath.split("/0/").last()
//        relativePath = relativePath.substring(0, relativePath.length - name.length - 1)
//        Log.i("MediaStore", relativePath);
//
//        val values = ContentValues().apply {
//            put(MediaStore.Images.Media.DISPLAY_NAME, name)
//            put(MediaStore.Images.Media.MIME_TYPE, mime)
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
////                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + File.separator + "Yaga")
//                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
//                put(MediaStore.Images.Media.IS_PENDING, 1)
//            }
//        }
//
//        val resolver = applicationContext.contentResolver
//        val uri = resolver.insert(collection, values)!!
//
//        try {
////            resolver.openOutputStream(uri).use { os ->
////                File(filePath).inputStream().use { it.copyTo(os!!) }
////            }
//
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
//                values.clear()
//                values.put(MediaStore.Images.Media.IS_PENDING, 0)
//                resolver.update(uri, values, null, null)
//            }
//        } catch (ex: IOException) {
//            Log.e("MediaStore", ex.message, ex)
//        }
//
//        return uri;
//    }
}
