package com.bevuta.androidChickenTest;

import android.os.Handler;
import android.os.Message;
import android.os.Bundle;
import android.util.Log;
import java.util.concurrent.locks.*;
import java.lang.reflect.Method;
import java.util.concurrent.ConcurrentLinkedQueue;

public class MethodArguments {

  public Object receiver;
  public Object[] args;
  
  public MethodArguments(Object receiver, Object[] args) {
    this.receiver = receiver;
    this.args = args;
  }

}
