package com.bevuta.androidChickenTest;

import android.app.Activity;
import android.view.View;
import android.widget.Button;
import android.os.Bundle;
import android.view.View.OnClickListener;
import android.util.Log;
import java.util.Random;

public class NativeChicken extends Activity
{
  public Backend backend = new Backend();

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    backend.activity = this;
    backend.onCreate();
    setContentView(R.layout.main);

    Button button = (Button)findViewById(R.id.button1);
    button.setOnClickListener(new OnClickListener() {
      @Override
      public void onClick(View v) {
        backend.onClick(v);
      }
    });
  }

  public void randomChange() {
    Random rand = new Random();
    Button button = (Button)findViewById(R.id.button1);
    button.setBackgroundColor(rand.nextInt());
  }

  @Override
  protected void onStart() {
    super.onStart();
    backend.onStart();
  }

  @Override
  protected void onResume() {
    super.onResume();
    backend.onResume();
  }

  @Override
  protected void onPause() {
    super.onPause();
    backend.onPause();
  }

  @Override
  protected void onStop() {
    super.onStop();
    backend.onStop();
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    backend.onDestroy();
  }
}
