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
                                     :gravity => Gravity::CENTER, :id => 42,
                                     :layout  => {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent}
          @report_button = button :text              => 'Report', :text_size => button_size,
                                  :id                => 43, :layout => {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent},
                                  :on_click_listener => proc { |view| handle_click(view) }
          @yaml_button   = button :text              => 'YAML', :text_size => button_size,
                                  :id                => 44, :layout => {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent},
                                  :on_click_listener => proc { |view| run_require_yaml_benchmark }
          @exit_button   = button :text              => 'Exit', :text_size => button_size,
                                  :id                => 45, :layout => {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent},
                                  :on_click_listener => proc { |view| handle_click(view) }
        end
  end

  def on_resume
    $package.StartupTimerActivity.stop ||= java.lang.System.currentTimeMillis
    require 'report'
    @benchmarks = {}
    @benchmarks['Startup']             ||= $package.StartupTimerActivity.stop - $package.StartupTimerActivity::START
    @name_view.text                    = "Startup"
    @duration_view.text                = "#{@benchmarks['Startup']} ms"
  end

  private

  def handle_click(view)
    case view
    when @report_button
      Report.send_report(self, @name_view.text, @benchmarks[@name_view.text])
    when @exit_button
      finish
      java.lang.System.runFinalizersOnExit(true)
      java.lang.System.exit(0)
    end
  end

  def run_require_yaml_benchmark
    benchmark_name = 'require yaml'
    Thread.with_large_stack do
      begin
        start = java.lang.System.currentTimeMillis
        require 'yaml'
        @benchmarks[benchmark_name] ||= java.lang.System.currentTimeMillis - start
        run_on_ui_thread do
          @name_view.text        = benchmark_name
          @duration_view.text    = "#{@benchmarks[benchmark_name]} ms"
          @report_button.enabled = false
          require 'report'
          Report.send_report(self, benchmark_name, @benchmarks[benchmark_name])
        end
      rescue
        puts $!
      end
    end
    true
  end
end
