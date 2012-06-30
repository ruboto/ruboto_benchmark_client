require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/util/stack'

ruboto_import_widgets :Button, :LinearLayout, :Spinner, :TextView

java_import android.view.Gravity
java_import java.lang.System

class StartupTimerActivity
  include Ruboto::Activity

  def on_create(bundle)
    set_title "Ruboto Benchmarks #{package_manager.getPackageInfo($package_name, 0).versionName}"

    layout_start = System.currentTimeMillis
    self.content_view =
        linear_layout :orientation => :vertical, :gravity => Gravity::CENTER do
          button_weight = 1
          button_size = [Java::android.util.TypedValue::COMPLEX_UNIT_PT, 20]
          button_layout = {:weight= => button_weight, :height= => :fill_parent, :width= => :fill_parent}

          @duration_view = text_view :id => 43, :text => "", :gravity => Gravity::CENTER, :layout => button_layout,
                                     :text_size => [Java::android.util.TypedValue::COMPLEX_UNIT_PT, 30]
          benchmarks = {
              'Startup' => proc {},
              'Layout' => proc {},
              'require yaml' => proc { require 'yaml' },
              'require active_record' => proc { require 'active_record' },
              'require AS dependencies' => proc { require 'active_support/deprecation'; require 'active_support/dependencies' },
              'Fibonacci , n=20' => proc { fib(20) },
              'TicTacToe' => proc { require 'tictactoe'; Game.new },
              'NOOP' => proc {},
          }

          @benchmark_view = spinner :id => 48, :list => benchmarks.keys, :layout => button_layout,
                                    :item_layout => $package.R::layout::spinner_layout,
                                    :on_item_selected_listener => proc { |spinner, view, position, id| view && benchmark(view.text, &benchmarks[view.text]) }

          button :id => 44, :text => 'Report', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { Report.send_report(self, @benchmark_view.selected_view.text, $benchmarks[@benchmark_view.selected_view.text]) }
          button :id => 56, :text => 'Exit', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { finish }
        end
    @layout_duration = System.currentTimeMillis - layout_start
  end

  def fib(n)
    n <= 2 ? 1 : fib(n-2) +fib(n-1)
  end


  def on_resume
    if $package.StartupTimerActivity.stop.nil?
      $package.StartupTimerActivity.stop = System.currentTimeMillis
      require 'report'
      $benchmarks = {}
      $benchmarks['Startup'] = $package.StartupTimerActivity.stop - $package.StartupTimerActivity::START - @layout_duration
      $benchmarks['Layout'] = @layout_duration
    end
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
