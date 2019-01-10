package com.foxit.cordova.plugin;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.foxit.sdk.common.Library;
import com.foxit.sdk.common.PDFException;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * This class echoes a string called from JavaScript.
 */
public class FoxitPdf extends CordovaPlugin {
    private CallbackContext callbackContext;
    private static final String RDK_DOCSAVED_EVENT = "onDocSaved";
    private static final String RDK_DOC_CLOSED_EVENT = "onDocClosed";
    
    private static int errCode = 0;
    private final static String sn = "XFasGJlbJhCyuCChjvaTZhYP48qPbcH6CHKVOYaOMp6ff7qkKsMTKQ==";
    private final static String key = "ezJvj90ntWp39JsXIV02hAkoHz2UIaApLY/TASnOq+HvnZAr455g+dgZ2rOwKqV3ji1R8nd+zUhrSSnmokSzw9EiWGPd1WjDHKOTA/eqNb+4n5zcXXqsucfMI6fOsUQoiZYtHVOR760n3eCrIP1sOQKBEEMJ0iwoh2SpQYfdZEL186cLa60q0+u/8ztlgKvzHEnnIf5tFYoF5Q1IVdhzzjG4Vry8r6tGiFXZTcD050OHhMpShd/7MfoFseG65Yyqnuum074i2w1DAKZI67ZKX0H1Dex9kvWfF1m/UUl4qz7beMBQ5IEmDwScpmLwLmyw1IR5xlRQ8sMr+Z5MpyXGpHvbzJa50mSsl9bS5cf4ctgNo7C+/Yt+U4ODtd8Ax+txSXbf71Qa+FaTDi2jrdQLlSo+8DUchEDIm4g35IC0RrdBSeMhI094ZxFbTRAHwgPoDXbc2fyaYtKRFFNjN9Yu/651D9zaZdOiDwWeeozGb2dF94ICk+JqsJuX8Epxh1Jhvst5PrNAgBI6e27t+vxsmx1vrwR6HtN5hY4BqWNF1PBP4AzvYJutiJ4/ZeJ7sbLRf8ERf9OVeobIjxY2SPgy62nF4Lckk/eG9lZsWyM2TlRn4lSEYRLVCmhMT7x+aqXkVCNVISilf/MhlNl1psxaKpWGXLrkVbTTrXoFQPUeSHLcd2KPFFUo6gAEMEjkOyklFCvnGj8wKIw1I3UCzuUsc5Qv49C+mR5wOpJt9v9OUbj3p7+HTGZpF4RY3B3rJkgsv3yWYG2M7orgrmGE4vF9cgWv42phioU0pw/oKwatsn4Me4sp7W6i6mdAQnS5ehDqqJpFWQY7j9HO60RGz9VXQzVrKLr5g4sGOx3GYk/LZnneWTllDtbm78tqSYvZjH4+zY6ZiqHdWCFKS6lNQVKVFgT8daeTS9iC+6D7CMRK9DARlaACFIhmo2pAXDaCJFuuQawRirQON3eqiBkSvanyMpUDpSrvW8V64DI0gA21CR0PQmRYeDcGuhw96F8VywZW5apPttBmmPXvi05j068zTJ1kHqqAYhGk07wKxhVZJ8Xy5oG4dBhfgqpUOsYeGE88FQxUcJ3YhsSpZ0Sbo9Xo3Arr1n1uH0Wfal2Vt0PGckP/4WbPhAWZWsOo8mjY8LhqOTd+Ii2PVANrHvLzfBh8er2b2TTPrxoaeqIljOGEX2Es6RBfJq9B9urx+ihzpY6qP9+T+kM=";

    public final static int result_flag = 1000;

    static {
        System.loadLibrary("rdk");
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;
        try {
            Library.init(sn, key);
            errCode = 0;
            if (action.equals("init")) {
                return true;
            }
            if (!action.equals("Preview")) {
                return false;
            }
            openDoc(args.getString(0), callbackContext);
            return true;
        } catch (PDFException e) {
            errCode = e.getLastError();
            callbackContext.error("Failed to initialize Foxit library.");
            return false;
        }
    }

    private void openDoc(final String path, final CallbackContext callbackContext) {
        if (path == null || path.trim().length() < 1) {
            callbackContext.error("Please input validate path.");
            return;
        }
        if (errCode != 0) {
            callbackContext.error("Please initialize Foxit library Firstly.");
        }
        Context context = this.cordova.getActivity();
        Activity activity = this.cordova.getActivity();
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            public void run() {
                FoxitPdf.this.openDocument(path, callbackContext);
            }
        });
    }

    private void openDocument(String file, CallbackContext callbackContext) {
        Intent intent = new Intent(this.cordova.getActivity(), ReaderActivity.class);
        Bundle bundle = new Bundle();
        bundle.putString("path", file);
        intent.putExtras(bundle);
        this.cordova.startActivityForResult(this, intent, 1000);
        this.cordova.setActivityResultCallback(this);
        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "Succeed open this file");
        pluginResult.setKeepCallback(true);
        this.callbackContext.sendPluginResult(pluginResult);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (resultCode == -1 && requestCode == 1000) {
            String returnedData = intent.getStringExtra("key");
            try {
                JSONObject obj = new JSONObject();
                obj.put("type", RDK_DOC_CLOSED_EVENT);
                obj.put("info", returnedData);
                if (this.callbackContext != null) {
                    PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
                    result.setKeepCallback(true);
                    this.callbackContext.sendPluginResult(result);
                }
            } catch (JSONException e) {
                Log.e("JSONException", "URI passed in has caused a JSON error.");
            }
        }
    }
}