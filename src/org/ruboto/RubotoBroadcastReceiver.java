package org.ruboto;

import java.io.IOException;

import org.ruboto.ScriptLoader;

public class RubotoBroadcastReceiver extends android.content.BroadcastReceiver implements org.ruboto.RubotoComponent {
    private final ScriptInfo scriptInfo = new ScriptInfo();
    private boolean scriptLoaded = false;

    public ScriptInfo getScriptInfo() {
        return scriptInfo;
    }

    public RubotoBroadcastReceiver() {
        this(null);
    }

    public RubotoBroadcastReceiver(String name) {
        super();

        if (name != null) {
            scriptInfo.setScriptName(name);
            if (JRubyAdapter.isInitialized()) {
                ScriptLoader.loadScript(this);
                scriptLoaded = true;
            }
        }
    }

    public void onReceive(android.content.Context context, android.content.Intent intent) {
        try {
            Log.d("onReceive: " + this + " " + ScriptLoader.isCalledFromJRuby() + " " + scriptLoaded);
            if (ScriptLoader.isCalledFromJRuby()) {
                return;
            }
            if (!scriptLoaded) {
                if (JRubyAdapter.setUpJRuby(context)) {
                    ScriptLoader.loadScript(this);
                    scriptLoaded = true;
                } else {
                    // FIXME(uwe): What to do if the Ruboto Core platform is missing?
                }
            }

            // FIXME(uwe): Simplify when we stop supporting JRuby 1.6.x
            if (JRubyAdapter.isJRubyPreOneSeven()) {
    	        JRubyAdapter.put("$broadcast_receiver", this);
    	        JRubyAdapter.put("$context", context);
    	        JRubyAdapter.put("$intent", intent);
                JRubyAdapter.runScriptlet("$broadcast_receiver.on_receive($context, $intent)");
            } else if (JRubyAdapter.isJRubyOneSeven()) {
            // FIXME(uwe):  Simplify when we stop support for snake case aliasing interface callback methods.
            if ((Boolean)JRubyAdapter.runScriptlet(scriptInfo.getRubyClassName() + ".instance_methods(false).any?{|m| m.to_sym == :onReceive}")) {
                Log.d("onReceive: call method");
    	        JRubyAdapter.runRubyMethod(this, "onReceive", new Object[]{context, intent});
            } else if ((Boolean)JRubyAdapter.runScriptlet(scriptInfo.getRubyClassName() + ".instance_methods(false).any?{|m| m.to_sym == :on_receive}")) {
    	        JRubyAdapter.runRubyMethod(this, "on_receive", new Object[]{context, intent});
            }
            // EMXIF
            } else {
                throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
        	}
        } catch(Exception e) {
            e.printStackTrace();
        }
    }

}
