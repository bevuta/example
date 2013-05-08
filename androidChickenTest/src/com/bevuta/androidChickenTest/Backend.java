package com.bevuta.androidChickenTest;

import android.os.Handler;
import android.os.Message;
import android.os.Bundle;
import android.util.Log;
import java.util.concurrent.locks.*;
import java.lang.reflect.Method;
import java.util.concurrent.ConcurrentLinkedQueue;
import android.view.View;

public class Backend implements Runnable
{
  private static final String TAG = "Backend";

  private native void main();
  public native void onCreate();
  public native void onStart();
  public native void onResume();
  public native void onPause();
  public native void onStop();
  public native void onDestroy();
  public native void onClick(View view);

  private Thread thread;
  private final Lock lock = new ReentrantLock();
  private final Condition chickenReady  = lock.newCondition(); 

  public NativeChicken activity;
  public ConcurrentLinkedQueue<MethodArguments> argumentsQueue = new ConcurrentLinkedQueue<MethodArguments>();

  protected Handler handler = new Handler() {
      @Override
      public void handleMessage(Message msg) {
        Log.d(TAG, "Processing message");
        Class<?> clazz = (Class<?>) msg.getData().getSerializable("class");
        Class<?>[] signature = (Class<?>[]) msg.getData().getSerializable("signature");
        String methodName =  msg.getData().getString("methodName");
        try {
          Method m = clazz.getMethod(methodName, signature);
          MethodArguments args = argumentsQueue.poll();
          if (args == null) {
            Log.e(TAG, "MethodArguments not found");
          } else {
            m.invoke(args.receiver, args.args);
          }
        } catch (Exception e) {
          Log.e(TAG, "Handler error", e);
        }
      }
  };

  public Backend() {       
    thread = new Thread(this);
    thread.start();

    try{	    
      lock.lock();
      chickenReady.await();
    } catch (InterruptedException exn){
    } finally {
      lock.unlock();
    }
  }

  public void run() {
    System.loadLibrary("chicken");
    System.loadLibrary("main");

    Log.d("Chicken Backend", "starting main loop...");
    main();
    Log.d("Chicken Backend", "main loop returned!");      
  }
}
