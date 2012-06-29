require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/util/stack'

ruboto_import_widgets :Button, :LinearLayout, :TextView

java_import android.view.Gravity

class StartupTimerActivity
  include Ruboto::Activity

  def on_create(bundle)
    set_title "Ruboto startup timer #{package_manager.getPackageInfo($package_name, 0).versionName}"

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => Gravity::CENTER do
          button_weight  = 1.5
          button_size    = [Java::android.util.TypedValue::COMPLEX_UNIT_PT, 14]
          @name_view     = text_view :text    => "", :text_size => button_size,
                                     :gravity => Gravity::CENTER, :id => 42,
                                     :layout  => {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent}
          @duration_view = text_view :text    => "", :text_size => button_size,
                                     :gravity => Gravity::CENTER, :id => 43,
                                     :layout  => {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent}
          button :text              => 'Report', :text_size => button_size,
                 :id                => 44, :layout => {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent},
                 :on_click_listener => proc { Report.send_report(self, @name_view.text, @benchmarks[@name_view.text]) }
          button :text              => 'Startup', :text_size => button_size,
                 :id                => 45, :layout => {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent},
                 :on_click_listener => proc { |view| benchmark(view.text) {} }
          button :text              => 'require active_record', :text_size => button_size,
                 :id                => 45, :layout => {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent},
                 :on_click_listener => proc { |view| benchmark(view.text) { require 'active_record' } }
          button :text              => 'require yaml', :text_size => button_size,
                 :id                => 46, :layout => {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent},
                 :on_click_listener => proc { |view| benchmark(view.text) { require 'yaml' } }
          button :text              => 'Exit', :text_size => button_size,
                 :id                => 47, :layout => {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent},
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
