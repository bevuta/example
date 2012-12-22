package com.bevuta.androidChickenTest;

import android.app.Activity;
import android.view.View;
import android.os.Bundle;
import android.util.Log;

public class NativeChicken extends Activity
{
    public Backend backend;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        backend = new Backend();

	Log.d("foo", "do i actually wait?");
	backend.sendEvent(Backend.ON_CREATE);
	Log.d("foo", "hmm?");
    }
}
