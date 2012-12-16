package com.bevuta.androidChickenTest;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import java.util.concurrent.ConcurrentLinkedQueue;

public class Backend implements Runnable
{

    private native void main();
    private native void signal();
    private int signalFd;
    private Thread thread;
    private ConcurrentLinkedQueue eventQueue;

    public Backend() {
        eventQueue = new ConcurrentLinkedQueue();
        thread = new Thread(this);
        thread.start();
    }

    public boolean sendEvent(Object o) {
        boolean result =  eventQueue.add(o);

        if (result) {
            signal();
        }

        return result;
    }

    public void run() {
	System.loadLibrary("chicken");
        System.loadLibrary("main");
        Log.d("foo", "starting backend");
        main();
        Log.d("foo", "done!");
    }
}
