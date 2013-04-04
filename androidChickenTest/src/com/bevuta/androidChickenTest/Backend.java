package com.bevuta.androidChickenTest;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import java.util.concurrent.locks.*;

public class Backend implements Runnable
{
  public enum ReturnValueType { VOID, BYTE, CHAR, SHORT, INT, LONG, DOUBLE, FLOAT, OBJECT}	

  public static class ReturnValue {
    public Object objectValue;
    public byte   byteValue;
    public char   charValue;
    public short  shortValue;
    public int    intValue;
    public long   longValue;
    public double doubleValue;
    public float  floatValue;
  }

  class ChickenCallback {
    public ReturnValueType valueType;
    public ReturnValue value;
    public Object sourceObject;

    public ChickenCallback(Object source, ReturnValueType t, ReturnValue v) {
      this.valueType = t;
      this.value = v;
      this.sourceObject = source;
    }
  }

  public static final int ON_CREATE = 0;
  public int eventType;

  private int signalFd;
  private native void main();
  private native void signal();

  private Thread thread;
  private final Lock lock = new ReentrantLock();
  private final Condition chickenReady  = lock.newCondition(); 

  protected int  createCallbackId;
  protected int   startCallbackId;
  protected int  resumeCallbackId;
  protected int   pauseCallbackId;
  protected int    stopCallbackId;
  protected int destroyCallbackId;


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

  public void sendEvent(int e) {
    try{	    
      lock.lock();

      eventType = e;
      signal();

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
