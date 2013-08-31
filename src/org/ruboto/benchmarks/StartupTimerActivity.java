package org.ruboto.benchmarks;

public class StartupTimerActivity extends org.ruboto.EntryPointActivity {
    public static final long START = System.currentTimeMillis();
    public static long jrubyStart;
    public static long jrubyLoaded;
    public static long fireRubotoActivity;
    public static long scriptLoaded;
    public static Long stop;
    public static long platformInstallationStart;
    public static long platformInstallationDone;

    public void onCreate(android.os.Bundle bundle) {
        super.onCreate(bundle);
        if (org.ruboto.JRubyAdapter.isInitialized()) {
            StartupTimerActivity.scriptLoaded = System.currentTimeMillis();
        }
    }
}
