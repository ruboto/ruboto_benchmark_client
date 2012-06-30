require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/util/stack'

ruboto_import_widgets :Button, :LinearLayout, :TextView

java_import android.view.Gravity
java_import java.lang.System

class StartupTimerActivity
  include Ruboto::Activity

  def on_create(bundle)
    set_title "Ruboto Benchmarks #{package_manager.getPackageInfo($package_name, 0).versionName}"

    layout_start = System.currentTimeMillis
    self.content_view =
        linear_layout :orientation => :vertical, :gravity => Gravity::CENTER do
          button_weight = 1.5
          button_size = [Java::android.util.TypedValue::COMPLEX_UNIT_PT, 11]
          button_layout = {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent}
          @name_view = text_view :id => 42, :text => "", :text_size => button_size, :gravity => Gravity::CENTER,
                                 :layout => button_layout
          @duration_view = text_view :text => "", :text_size => button_size,
                                     :gravity => Gravity::CENTER, :id => 43,
                                     :layout => button_layout
          button :id => 44, :text => 'Report', :layout => button_layout,
                 :on_click_listener => proc { Report.send_report(self, @name_view.text, $benchmarks[@name_view.text]) }
          button :id => 45, :text => 'Startup', :layout => button_layout,
                 :on_click_listener => proc { |view| benchmark(view.text) {} }
          button :id => 46, :text => 'Layout', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { |view| benchmark(view.text) {} }
          button :id => 47, :text => 'require yaml', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { |view| benchmark(view.text) { require 'yaml' } }
          button :id => 48, :text => 'require active_record', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { |view| benchmark(view.text) { require 'active_record' } }
          button :id => 49, :text => 'require AS dependencies', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { |view| benchmark(view.text) { require 'active_support/deprecation'; require 'active_support/dependencies' } }
          button :id => 50, :text => 'TicTacToe', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { |view| benchmark(view.text) { require 'tictactoe'; Game.new } }

          button :id => 56, :text => 'Exit', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { finish }
        end
    @layout_duration = System.currentTimeMillis - layout_start
  end

  def on_resume
    if $package.StartupTimerActivity.stop.nil?
      $package.StartupTimerActivity.stop = System.currentTimeMillis
      require 'report'
      $benchmarks = {}
      $benchmarks['Startup'] = $package.StartupTimerActivity.stop - $package.StartupTimerActivity::START - @layout_duration
      $benchmarks['Layout'] = @layout_duration
    end
    @name_view.text = "Startup"
    @duration_view.text = "#{$benchmarks['Startup']} ms"
  end

  private

  def finish
    super
    java.lang.System.runFinalizersOnExit(true)
    java.lang.System.exit(0)
  end

  def benchmark(benchmark_name, &block)
    if $benchmarks[benchmark_name]
      @name_view.text = benchmark_name
      @duration_view.text = "#{$benchmarks[benchmark_name]} ms"
      return
    end
    message = "Running '#{benchmark_name}' benchmark..."
    loadingDialog = android.app.ProgressDialog.show(@java_instance, nil, message, true, true)
    loadingDialog.canceled_on_touch_outside = false
    puts message
    Thread.with_large_stack do
      begin
        start = System.currentTimeMillis
        block.call
        $benchmarks[benchmark_name] = System.currentTimeMillis - start
        puts "Benchmark '#{benchmark_name}' completed in #{$benchmarks[benchmark_name]}ms."
        run_on_ui_thread do
          @name_view.text = benchmark_name
          @duration_view.text = "#{$benchmarks[benchmark_name]} ms"
        end
      rescue
        puts $!
        puts $!.backtrace.join("\n")
      ensure
        loadingDialog.dismiss
      end
    end
    true
  end

end
