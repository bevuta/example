package com.bevuta.androidChickenTest;

import android.app.Activity;
import android.view.View;
import android.os.Bundle;
import android.util.Log;

public class NativeChicken extends Activity
{
    public Backend backend = new Backend();

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
	backend.sendEvent(backend.createCallbackId);
    }
    @Override
    protected void onStart() {
        super.onStart();
	backend.sendEvent(backend.startCallbackId);
    }
    @Override
    protected void onResume() {
        super.onResume();
	backend.sendEvent(backend.resumeCallbackId);
    }
    @Override
    protected void onPause() {
        super.onPause();
	backend.sendEvent(backend.pauseCallbackId);
    }
    @Override
    protected void onStop() {
        super.onStop();
	backend.sendEvent(backend.stopCallbackId);
    }
    @Override
    protected void onDestroy() {
        super.onDestroy();
	backend.sendEvent(backend.destroyCallbackId);
    }
}
