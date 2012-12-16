package com.bevuta.androidChickenTest;

import android.app.Activity;
import android.view.View;
import android.os.Bundle;

public class NativeChicken extends Activity
{
    public Backend backend;

    class Event {
        public Object eventTarget;
        public String eventType;

        public Event(String type, Object target) {
            eventType = type;
            eventTarget = target;
        }
    }


    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        backend = new Backend();
    }

    public void jniCall(View view) {
        backend.sendEvent(new Event("click", view));
    }
}
