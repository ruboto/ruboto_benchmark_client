require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/util/stack'

ruboto_import_widgets :Button, :LinearLayout, :TextView

java_import android.view.Gravity

class StartupTimerActivity
  include Ruboto::Activity

  def on_create(bundle)
    set_title "Ruboto Benchmarks #{package_manager.getPackageInfo($package_name, 0).versionName}"

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => Gravity::CENTER do
          button_weight  = 1.5
          button_size    = [Java::android.util.TypedValue::COMPLEX_UNIT_PT, 11]
          button_layout  = {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent}
          @name_view     = text_view :text    => "", :text_size => button_size,
                                     :gravity => Gravity::CENTER, :id => 42,
                                     :layout  => button_layout
          @duration_view = text_view :text    => "", :text_size => button_size,
                                     :gravity => Gravity::CENTER, :id => 43,
                                     :layout  => button_layout
          button :id                => 44, :text => 'Report', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { Report.send_report(self, @name_view.text, @benchmarks[@name_view.text]) }
          button :id                => 45, :text => 'Startup', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { |view| benchmark(view.text) {} }
          button :id                => 46, :text => 'require yaml', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { |view| benchmark(view.text) { require 'yaml' } }
          button :id                => 47, :text => 'require active_record', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { |view| benchmark(view.text) { require 'active_record' } }
          button :id                => 48, :text => 'require AS dependencies', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { |view| benchmark(view.text) { require 'active_support/deprecation' ; require 'active_support/dependencies' } }

          button :id                => 56, :text => 'Exit', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { finish }
        end
  end

  def on_resume
    $package.StartupTimerActivity.stop ||= java.lang.System.currentTimeMillis
    require 'report'
    @benchmarks            ||= {}
    @benchmarks['Startup'] ||= $package.StartupTimerActivity.stop - $package.StartupTimerActivity::START
    @name_view.text        = "Startup"
    @duration_view.text    = "#{@benchmarks['Startup']} ms"
  end

  private

  def finish
    super
    java.lang.System.runFinalizersOnExit(true)
    java.lang.System.exit(0)
  end

  def benchmark(benchmark_name, &block)
    if @benchmarks[benchmark_name]
      @name_view.text     = benchmark_name
      @duration_view.text = "#{@benchmarks[benchmark_name]} ms"
      return
    end
    loadingDialog                           = android.app.ProgressDialog.show(@java_instance, nil, "Running '#{benchmark_name}' benchmark...", true, true)
    loadingDialog.canceled_on_touch_outside = false
    Thread.with_large_stack do
      begin
        start = java.lang.System.currentTimeMillis
        block.call
        @benchmarks[benchmark_name] ||= java.lang.System.currentTimeMillis - start
        run_on_ui_thread do
          @name_view.text     = benchmark_name
          @duration_view.text = "#{@benchmarks[benchmark_name]} ms"
        end
      rescue
        puts $!
      ensure
        loadingDialog.dismiss
      end
    end
    true
  end

end
