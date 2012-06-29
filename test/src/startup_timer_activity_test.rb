activity Java::org.ruboto.startup_timer.StartupTimerActivity

setup do |activity|
  start = Time.now
  loop do
    @name_view = activity.findViewById(42)
    break if @name_view || (Time.now - start > 60)
    sleep 1
  end
  assert @name_view
end

test('initial setup') do |activity|
  assert_matches /Startup took \d+ ms/, @name_view.text
end
