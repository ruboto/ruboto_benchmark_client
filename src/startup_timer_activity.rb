require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/util/stack'

ruboto_import_widgets :Button, :ImageView, :LinearLayout, :TextView

java_import android.view.Gravity

class StartupTimerActivity
  include Ruboto::Activity

  def on_create(bundle)
    set_title "Ruboto startup timer #{package_manager.getPackageInfo($package_name, 0).versionName}"

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => Gravity::CENTER do
          button_weight = 1.5
          image_view :image_resource => $package::R::drawable::icon, :scale_type => ImageView::ScaleType::FIT_CENTER,
                     :layout         => {:weight= => 1, :height= => :fill_parent, :width= => :fill_parent}
          button_size    = [Java::android.util.TypedValue::COMPLEX_UNIT_PT, 14]
          @text_view     = text_view :text    => "", :text_size => button_size,
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
    @startup_time                      ||= $package.StartupTimerActivity.stop - $package.StartupTimerActivity::START
    @text_view.text                    = "Startup took #{@startup_time} ms"
  end

  private

  def handle_click(view)
    case view
    when @report_button
      java_import android.content.Intent
      java_import android.net.Uri
      java_import android.util.Log

      require 'report'
      Report.send_report(self, true, @startup_time)
    when @exit_button
      finish
      java.lang.System.runFinalizersOnExit(true)
      java.lang.System.exit(0)
    end
  end

  def run_require_yaml_benchmark
    Thread.with_large_stack do
      begin
        start = java.lang.System.currentTimeMillis
        require 'yaml'
        duration = java.lang.System.currentTimeMillis - start
        run_on_ui_thread do
          @text_view.text        = "Require YAML took #{duration} ms"
          @report_button.enabled = false
        end
      rescue
        puts $!
      end
    end
  end
end
