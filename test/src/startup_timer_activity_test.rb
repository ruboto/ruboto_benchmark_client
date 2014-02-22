activity Java::org.ruboto.benchmarks.StartupTimerActivity

setup do |activity|
  start = Time.now
  loop do
    @name_view = activity.findViewById(43)
    break if @name_view || (Time.now - start > 60)
    sleep 1
  end
  assert @name_view
end

test('initial setup') do |activity|
  assert_matches /\d+ ms/, @name_view.text.to_s
end
