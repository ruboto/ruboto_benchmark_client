package org.ruboto.benchmarks;

import android.os.Bundle;

public class StartupTimerActivity extends org.ruboto.EntryPointActivity {
    public static final long START = System.currentTimeMillis();
    public static long jrubyStart;
    public static long jrubyLoaded;
    public static long fireRubotoActivity;
    public static long scriptLoaded;
    public static Long stop;

	public void onCreate(Bundle bundle) {
		setScriptName("startup_timer_activity.rb");
	    super.onCreate(bundle);
	}
}
