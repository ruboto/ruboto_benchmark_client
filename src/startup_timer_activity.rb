require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/util/stack'

ruboto_import_widgets :Button, :LinearLayout, :Spinner, :TextView

java_import java.lang.System

class StartupTimerActivity
  def on_create(bundle)
    set_title "Ruboto Benchmarks #{package_manager.getPackageInfo($package_name, 0).versionName} #{System.getProperty("jruby.compat.version").capitalize} #{System.getProperty("jruby.compile.mode").downcase}"

    layout_start = System.currentTimeMillis
    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center do
          button_weight = 1
          button_size = [Java::android.util.TypedValue::COMPLEX_UNIT_PT, 20]
          button_layout = {:weight= => button_weight, :height= => :match_parent, :width= => :match_parent}

          @duration_view = text_view :id => 43, :text => "", :gravity => :center, :layout => button_layout,
                                     :text_size => [Java::android.util.TypedValue::COMPLEX_UNIT_PT, 30]
          benchmarks = {
              'Startup' => proc {},
              'RubotoCore Install' => proc {},
              'Layout' => proc {},
              'JRuby Runtime pre' => proc {},
              'JRuby Runtime load' => proc {},
              'Platform Runtime load' => proc {},
              'JRuby Runtime prep' => proc {},
              'Script load' => proc {},
              'Script resume' => proc {},
              'require yaml' => proc { require 'yaml' },
              'require active_record' => proc { require 'active_record' },
              'require AS dependencies' => proc { require 'active_support/deprecation'; require 'active_support/dependencies' },
              'Fibonacci, n=20' => proc { fib(20) },
              'Fibonacci, n=25' => proc { fib(25) },
              'TicTacToe' => proc { require 'tictactoe'; Game.new },
              'NOOP' => proc {},
        		  'require json' => proc { require 'json/pure' },
      			  'require tmail' => proc { require 'tmail' },			  
##      			  'SQLdroid' => proc { require "sqldroid/version" ; require "sqldroid/sqldroid-0.3.0"  }, #needs to be modified
			  
          }

          @benchmark_view =
              spinner :id => 48, :list => benchmarks.keys, :layout => button_layout,
                      :item_layout => $package.R::layout::spinner_layout,
                      :on_item_selected_listener => proc { |spinner, view, position, id| view && benchmark(view.text, &benchmarks[view.text]) }

          button :id => 44, :text => 'Report', :text_size => button_size, :layout => button_layout,
                 :on_click_listener => proc { Report.send_report(self, @benchmark_view.selected_view.text, $benchmarks[@benchmark_view.selected_view.text]) }
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
      ruboto_core_install = $package.StartupTimerActivity.platformInstallationDone.to_i - $package.StartupTimerActivity.platformInstallationDone.to_i
      $benchmarks['RubotoCore Install'] = ruboto_core_install
      $benchmarks['Startup'] = $package.StartupTimerActivity.stop - $package.StartupTimerActivity::START - ruboto_core_install - @layout_duration
      $benchmarks['Layout'] = @layout_duration
      $benchmarks['JRuby Runtime pre'] = $package.StartupTimerActivity.jrubyStart - $package.StartupTimerActivity::START
      $benchmarks['JRuby Runtime load'] = $package.StartupTimerActivity.jrubyLoaded - $package.StartupTimerActivity.jrubyStart
      $benchmarks['JRuby Runtime prep'] = $package.StartupTimerActivity.fireRubotoActivity - $package.StartupTimerActivity.jrubyLoaded
      $benchmarks['Script load'] = $package.StartupTimerActivity.scriptLoaded - $package.StartupTimerActivity.fireRubotoActivity
      $benchmarks['Script resume'] = $package.StartupTimerActivity.stop - $package.StartupTimerActivity.scriptLoaded
    end
    @duration_view.text = "#{$benchmarks['Startup']} ms"
  end

  def finish
    super
    java.lang.System.runFinalizersOnExit(true)
    java.lang.System.exit(0)
  end

  private

  def fib(n)
    n <= 2 ? 1 : fib(n-2) + fib(n-1)
  end

  def benchmark(benchmark_name, &block)
    if $benchmarks[benchmark_name]
      @duration_view.text = "#{$benchmarks[benchmark_name]} ms"
      return
    end
    message = "Running '#{benchmark_name}' benchmark..."
    loadingDialog = android.app.ProgressDialog.show(self, nil, message, true, true)
    loadingDialog.canceled_on_touch_outside = false
    getWindow().addFlags(android.view.WindowManager::LayoutParams::FLAG_KEEP_SCREEN_ON)
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
        run_on_ui_thread do
          getWindow().clearFlags(android.view.WindowManager::LayoutParams::FLAG_KEEP_SCREEN_ON)
        end
      end
    end
    true
  end

end
