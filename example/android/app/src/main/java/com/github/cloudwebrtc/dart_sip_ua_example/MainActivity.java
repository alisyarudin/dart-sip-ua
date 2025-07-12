package com.github.cloudwebrtc.dart_sip_ua_example;

import android.content.Intent;
import android.os.Bundle;
import io.flutter.embedding.android.FlutterFragmentActivity;

public class MainActivity extends FlutterFragmentActivity {
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
    }
}
