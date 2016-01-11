require 'ruboto/version'

class Report
  java_import android.content.Intent
  java_import android.net.Uri
  java_import android.util.Log

  java_import org.apache.http.client.entity.UrlEncodedFormEntity
  java_import org.apache.http.client.methods.HttpGet
  java_import org.apache.http.client.methods.HttpPost
  java_import org.apache.http.client.protocol.ClientContext
  java_import org.apache.http.impl.client.BasicCookieStore
  java_import org.apache.http.impl.client.DefaultHttpClient
  java_import org.apache.http.message.BasicNameValuePair
  java_import org.apache.http.protocol.BasicHttpContext
  java_import org.apache.http.util.EntityUtils

  SERVER_BASE ='https://ruboto-startup.herokuapp.com/measurements'
  # SERVER_BASE ='http://192.168.0.100:3000/measurements' # Uwe's development laptop at home
  # SERVER_BASE ='http://10.10.1.190:3000/measurements' # Uwe's development laptop at work
  # SERVER_BASE ='http://192.168.137.41:3000/measurements' # Akshay's development laptop

  def self.send_report(activity, test_name, duration)
    activity.toast "Sending '#{test_name}' measurement"
    Thread.start do
      begin
        http_context = BasicHttpContext.new
        http_context.setAttribute(ClientContext.COOKIE_STORE, BasicCookieStore.new)
        http_client = DefaultHttpClient.new

        Log.i 'RubotoStartupTimer', 'Get form'
        get_form_method = HttpGet.new("#{SERVER_BASE}/new")
        response = http_client.execute(get_form_method, http_context)
        form_body = EntityUtils.toString(response.entity)
        if form_body =~ %r{<input [^>]*name="authenticity_token" [^>]*value="([^"]*)"}
          authenticity_token = $1
          Log.i 'RubotoStartupTimer', authenticity_token
        else
          activity.run_on_ui_thread do
            activity.toast 'Could NOT send the report! (Unable to find the form token.)'
          end
          next
        end

        Log.i 'RubotoStartupTimer', 'Post startup time'
        create_method = HttpPost.new("#{SERVER_BASE}")
        create_method.setHeader("Content-Type", "application/x-www-form-urlencoded")
        list = [
            BasicNameValuePair.new('authenticity_token', authenticity_token),
            BasicNameValuePair.new('measurement[package]', $package_name),
            BasicNameValuePair.new('measurement[package_version]', activity.package_manager.getPackageInfo($package_name, 0).versionName),
            BasicNameValuePair.new('measurement[test]', test_name),
            BasicNameValuePair.new('measurement[duration]', duration.to_s),
            BasicNameValuePair.new('measurement[manufacturer]', android.os.Build::MANUFACTURER),
            BasicNameValuePair.new('measurement[model]', android.os.Build::MODEL),
            BasicNameValuePair.new('measurement[android_version]', android.os.Build::VERSION::RELEASE),
            BasicNameValuePair.new('measurement[ruboto_platform_version]', org.ruboto.JRubyAdapter.usesPlatformApk() ? activity.package_manager.getPackageInfo('org.ruboto.core', 0).versionName : "JRuby #{org.ruboto.JRubyAdapter.get("JRUBY_VERSION")}"),
            BasicNameValuePair.new('measurement[ruboto_app_version]', Ruboto::VERSION),
            BasicNameValuePair.new('measurement[compile_mode]', System.getProperty("jruby.compile.mode")),
            BasicNameValuePair.new('measurement[ruby_version]', System.getProperty("jruby.compat.version")),
        ]
        entity = UrlEncodedFormEntity.new(list)
        create_method.setEntity(entity)
        create_response = http_client.execute(create_method, http_context)
        create_body = EntityUtils.toString(create_response.entity)

        if create_response.status_line.status_code == 200
          Log.i 'RubotoStartupTimer', 'Results saved!'
          activity.run_on_ui_thread do
            activity.toast 'Results saved!'
            activity.startActivity(Intent.new(Intent::ACTION_VIEW, Uri.parse("#{Report::SERVER_BASE}")))
            activity.finish
          end
        else
          Log.i 'RubotoStartupTimer', "Request failed"
          Log.i 'RubotoStartupTimer', create_body
          activity.run_on_ui_thread { activity.toast 'Saving failed!' }
        end
      rescue
        Log.e 'RubotoStartupTimer', "Exception: #{$!}\n#{$!.backtrace.join("\n")}"
      ensure
        http_client.try :close
      end
    end
  end
end
