# TASKGRACKLE - Helper module

class Helper

  SPEEDS = ['Vacation', 'Slow', 'Normal', 'Crunch']
  SPEEDMAP = {"v": 0, "s": 1, "n": 2, "c": 3}

  # Time helpers
  def self.minutes_since_last_checkin(checkins)
    if checkins.last
      get_minutes_since(checkins.last[0])
    else
      6000 # a high default ceiling
    end
  end

  def self.get_minutes_since(time)
    if time
      (Time.now - time) / 60   # seconds in an minute
    else
      6000  # a high default ceiling
    end
  end

  def self.get_hours_since(time)
    if time
      (Time.now - time) / 3600   # seconds in an hour
    else
      100  # a high default ceiling
    end
  end

  def self.get_days_since(time)
    if time
      (Time.now - time) / 86400   # seconds in a day
    else
      365  # a high default ceiling
    end
  end


  def self.checked_in_today(checkins)
    checkins.each do |checkin|
      checkin_is_today = checkin[0].year == Time.now.year &&
                         checkin[0].month == Time.now.month &&
                         checkin[0].day == Time.now.day &&
                         checkin[0].hour >= 5 #am
      return true if checkin_is_today
    end
    false
  end

  def self.last_checkin_for(key, checkins)
    the_date = nil
    checkins.reverse.each do |checkin|
      if checkin[1].include?(key)
        the_date = checkin[0]
        break
      end
    end
    the_date
  end

  # 5am begins the day
  def self.get_beginning_of_day
    Time.new(Time.now.year, Time.now.month, Time.now.day, 5)
  end

  # key_s: a key, or an array of keys
  def self.has_checked_in_key_today?(key_s, checkins)
    checkins_today_of(key_s, checkins) > 0
  end

  def self.checkins_today_of(key_s, checkins)
    all_checkin_codes = checkins_today(checkins).collect{|x| x[1] }.join("")

    if key_s.is_a?(String)
      all_checkin_codes.count(key_s)
    else
      total = 0
      key_s.each do |key_from_array|
        total += all_checkin_codes.count(key_from_array)
      end
      total
    end
  end

  def self.checkins_today(checkins)
    checkins.select{|x| x[0] > get_beginning_of_day}
  end

  def self.total_checkins_today(checkins)
    checkins_today(checkins).size
  end

  def self.checkins_in_last_24_hours(checkins)
    checkins.select{|x| x[0] > (Time.now - (24 * 60 * 60))}.size
  end

  def self.due_for_mood_checkup?(moodlist)
    hours_since_last_mood_checkup(moodlist) >= 24
  end

  def self.hours_since_last_mood_checkup(moodlist)
    if moodlist.last
      get_hours_since(moodlist.last[0])
    else
      72 # a high default ceiling
    end
  end

  def self.needs_exercise?(tasks, checkins)
    return false if checkins.size < 3
    exercise_keys = tasks.select{|key, task| task['category'] == 'Exercise'}
                         .collect{|key, task| key}
    !has_checked_in_key_today?(exercise_keys, checkins)
  end


  ## SETTINGS

  def self.get_settings_from_json_or_create
    default_settings = {:speed => 2, :annoying => 1, :vice => 0}
    begin
      file = File.read('./data/settings.json')
      JSON.parse(file, {:symbolize_names => true})

    rescue
      write_settings(default_settings)
      default_settings
    end
  end

  def self.get_setting(setting_sym)
    settings = get_settings_from_json_or_create
    settings[setting_sym]
  end

  def self.set_setting(setting_sym, new_value)
    settings = get_settings_from_json_or_create
    settings[setting_sym] = new_value
    self.write_settings(settings)
    settings
  end

  def self.write_settings(settings_obj)
    File.open("./data/settings.json", "w") do |f|
      f.write(settings_obj.to_json)
      f.close
    end
  end

  def self.update_last_interacted
    File.open("./data/last_checkin.time", "w") do |f|
      f.write(Time.now.to_i)
      f.close
    end
  end

  def self.place_squawkblocker
    File.open("./data/squawk.blocker", "w") do |f|
      f.write('Graaak! Sounds blocked.')
      f.close
    end
  end

  def self.remove_squawkblocker
    File.delete("./data/squawk.blocker")
    update_last_interacted
  end

  # SPEED

  def self.set_speed(new_speed)
    settings = get_settings_from_json_or_create
    settings[:speed] = SPEEDMAP[new_speed.to_sym]  # get the int of the speed
    self.write_settings(settings)
    settings
  end

  def self.get_speed
    settings = get_settings_from_json_or_create
    SPEEDS[ settings[:speed] ]
  end

  def self.speed_indicator
    case get_speed
    when "Vacation"
      indicator = "v".colorize(:magenta)
    when "Slow"
      indicator = "s".colorize(:light_blue)
    when "Normal"
      indicator = "n".colorize(:green)
    when "Crunch"
      indicator = "c".colorize(:red)
    end
    "#{indicator}"
  end

  def self.is_on_vacation?
    get_speed == "Vacation"
  end

  def self.is_in_slow_mode?
    get_speed == "Slow"
  end

  def self.is_taking_it_easy?
    is_on_vacation? || is_in_slow_mode?
  end

  def self.is_in_crunch?
    get_speed == "Crunch"
  end

  ## ANNOYANCES

  def self.in_annoying_mode?
    get_setting(:annoying) == 1
  end

  ## VICE

  def self.in_vicetracking_mode?
    get_setting(:vice) == 1
  end

  ## FRIENDS

  def self.last_contacted_friend(key, commlist)
    the_date = nil
    commlist.reverse.each do |comm|
      if comm[1] == key
        the_date = comm[0]
        break
      end
    end
    the_date
  end

  def self.last_engaged_with_community(k, engagelist)
    the_date = nil
    engagelist.reverse.each do |engagement|
      if engagement[1] == k
        the_date = engagement[0]
        break
      end
    end
    the_date
  end

  ## OTHER

  def self.power_month_indicator
    power_months = [2, 4, 6, 9, 11]
    if power_months.include?(Time.now.month)
      "!".colorize(:light_yellow)
    else
      ""
    end
  end

  def self.get_gracklecoin_balance
    default_coins = {:balance => 0}
    begin
      file = File.read('./data/gracklecoin.json')
      json = JSON.parse(file, {:symbolize_names => true})
      json[:balance].to_i
    rescue
      self.update_gracklecoin_balance(default_coins)
      default_coins[:balance]
    end
  end

  def self.update_gracklecoin_balance(new_balance)
    coin_obj = {:balance => new_balance}

    File.open("./data/gracklecoin.json", "w") do |f|
      f.write(coin_obj.to_json)
      f.close
    end
  end

  def self.get_gracklecoin(coins_received)
    balance = get_gracklecoin_balance
    balance += coins_received
    update_gracklecoin_balance(balance)
  end

  def self.spend_gracklecoin(coins_spent)
    balance = get_gracklecoin_balance
    balance -= coins_received
    update_gracklecoin_balance(balance)
  end
end
