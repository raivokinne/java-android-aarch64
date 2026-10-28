package com.example.hello;

import android.app.Activity;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.LinearLayout;
import android.widget.TextView;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        LinearLayout layout = new LinearLayout(this);
        layout.setGravity(Gravity.CENTER);
        TextView label = new TextView(this);
        label.setText("Hello, World!");
        label.setTextSize(24);
        layout.addView(label);
        setContentView(layout);
    }
}
