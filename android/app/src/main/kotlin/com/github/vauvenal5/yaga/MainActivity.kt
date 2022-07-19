package com.github.vauvenal5.yaga

import android.content.Intent;
import android.os.Bundle;
import android.net.Uri;
import android.provider.MediaStore;import android.content.ContentValues;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val INTENT_CHANNEL = "yaga.channel.intent";
    private val GET_INTENT_ACTION_METHOD = "getIntentAction";
    private val GET_INTENT_TYPE_METHOD = "getIntentType";
    private val GET_INTENT_SET_RESULT = "setSelectedFile";

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        val intent = getIntent();

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL).setMethodCallHandler {
                call, result ->
            if(call.method.contentEquals(GET_INTENT_ACTION_METHOD)) {
                result.success(intent.getAction());
            } else if (call.method.contentEquals(GET_INTENT_TYPE_METHOD)) {
                result.success(intent.getType());
            } else if (call.method.contentEquals(GET_INTENT_SET_RESULT)) {
                val res = Intent();
                val name = call.argument<String>("name");
                val path = call.argument<String>("path");
                val mime = call.argument<String>("mime");

                if(name == null || path == null || mime == null) {
                    result.success(false);
                }

                res.setData(getUriFromPath(name!!, path!!, mime!!));
                setResult(RESULT_OK, res);
                finish();
            } else {
                result.notImplemented()
            }
        };
    }

    /**
     * Returns the Uri which can be used to delete/work with images in the photo gallery.
     * @param filePath Path to IMAGE on SD card
     * @return Uri in the format of... content://media/external/images/media/[NUMBER]
     */
    private fun getUriFromPath(name: String, filePath: String, mime: String): Uri {
        //todo: this is only a very simplistic implementation: read up on MediaStore and improve appropriately
        val values = ContentValues();
        values.put(MediaStore.Images.Media.TITLE, name);
        values.put(MediaStore.Images.Media.DESCRIPTION, "Image from Nextcloud Yaga.");
        values.put(MediaStore.Images.Media.MIME_TYPE, mime);
        values.put("_data", filePath);
        getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);

        val photoUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

        val projection = arrayOf(MediaStore.Images.ImageColumns._ID);
        // TODO This will break if we have no matching item in the MediaStore.
        val cursor = getContentResolver().query(photoUri, projection, MediaStore.Images.ImageColumns.DATA + " LIKE ?", arrayOf(filePath), null);

        if(cursor == null) {
            return Uri.parse(filePath);
        }

        cursor.moveToFirst();

        val columnIndex = cursor.getColumnIndex(projection[0]);
        val photoId = cursor.getLong(columnIndex);

        cursor.close();
        return Uri.parse(photoUri.toString() + "/" + photoId);
    }
}
