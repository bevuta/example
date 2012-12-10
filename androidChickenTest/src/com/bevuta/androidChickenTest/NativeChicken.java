package com.bevuta.androidChickenTest;

import android.app.NativeActivity;
import android.os.Bundle;


public class NativeChicken extends NativeActivity
{
    static {
	System.loadLibrary("chicken");
    }
}
