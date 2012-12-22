package com.bevuta.androidChickenTest;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import java.util.concurrent.locks.*;

public class Backend implements Runnable
{
    public static class ReturnValue {
	public enum ReturnValueType { BYTE, CHAR, SHORT, INT, LONG, DOUBLE, FLOAT, OBJECT}	
	public int    type;

	public Object objectValue;
	public byte   byteValue;
	public char   charValue;
	public short  shortValue;
	public int    intValue;
	public long   longValue;
	public double doubleValue;
	public float  floatValue;
    }

    class Event {
        public Object eventTarget;
        public String eventType;

        public Event(String type, Object target) {
            eventType = type;
            eventTarget = target;
        }

	@Override 
	public String toString() {
	    return super.toString() + " [ " + eventType + " / " + eventTarget.toString() + " ]";
	}
    }
    
    private int signalFd;
    private native void main();
    private native void signal();

    private Thread thread;
    private final Lock lock = new ReentrantLock();
    private final Condition chickenReady  = lock.newCondition(); 


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

    public void sendEvent(Object o) {
	signal();
    }

    public void run() {
	System.loadLibrary("chicken");
	System.loadLibrary("main");
	Log.d("Chicken Backend", "starting main loop...");
	main();
	Log.d("Chicken Backend", "main loop returned!");      
    }
}
