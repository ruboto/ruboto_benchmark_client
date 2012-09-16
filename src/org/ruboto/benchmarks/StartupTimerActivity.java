package org.ruboto.benchmarks;

import android.os.Bundle;

public class StartupTimerActivity extends org.ruboto.EntryPointActivity {
    public static final long START = System.currentTimeMillis();
    public static long jrubyStart;
    public static long jrubyLoaded;
    public static long fireRubotoActivity;
    public static long scriptLoaded;
    public static Long stop;
    public static long platformInstallationStart;
    public static long platformInstallationDone;

	public void onCreate(Bundle bundle) {
		getScriptInfo().setRubyClassName(getClass().getSimpleName());
	    super.onCreate(bundle);
	}
}
