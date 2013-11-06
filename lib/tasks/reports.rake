namespace :reports do

  def set_up_progress_user(total)
    @total = total
    print '|' + ' ' * 100 + '|' + ' ' * (9 + 2 * total.to_s.length)
    $stdout.flush
  end

  def progress_user(amount)
    percent = amount * 100 / @total
    print "\b" * (111 + 2 * @total.to_s.length)
    print '|' + '#' * percent + ' ' * (100 - percent) + '| '
    print ' ' if percent < 10
    print ' ' if percent < 100
    print percent
    print '%'
    print ' (' + (' ' * (@total.to_s.length - amount.to_s.length)) + amount.to_s + '/' + @total.to_s + ')'
    $stdout.flush
  end

  desc "account usage reports"
  task usage: [:environment] do
    done = 0
    set_up_progress_user(User.count)
    User.find_each do |user|
      user.update_usage_report!
      done += 1
      progress_user(done)
    end
    puts "done!"
  end
end
