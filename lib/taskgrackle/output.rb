# TASKGRACKLE - Output module

require 'colorize'
require 'httparty'

require_relative 'helper'

class Output

  TASK_COLOR = :light_yellow
  GRACKLE_COLOR = :light_cyan
  DATE_COLOR = :light_blue

  DUE_COLOR      = :cyan
  OVERDUE_COLOR  = :light_cyan
  URGENT_COLOR   = :yellow
  V_URGENT_COLOR = :light_red
  X_URGENT_COLOR = :red

  MORNING_COLOR = :light_yellow
  AFTERNOON_COLOR = :green
  EVENING_COLOR = :yellow
  NIGHT_COLOR = :red
  MOOD_COLOR = :light_blue
  EXERCISE_COLOR = :green
  DARKMOON_COLOR = :blue
  BRIGHTMOON_COLOR = :light_blue
  SPRING_COLOR = :magenta
  SUMMER_COLOR = :light_green
  FALL_COLOR = :orange
  WATER_COLOR = :light_cyan
  WINTER_COLOR = :light_cyan

  LATE_NIGHT = "Late night"
  MORNING = "Morning"
  AFTERNOON = "Afternoon"
  EVENING = "Evening"
  NIGHT = "Night"

  MORNING_THRESHOLD = 5
  AFTERNOON_THRESHOLD = 12
  EVENING_THRESHOLD = 17
  NIGHT_THRESHOLD = 21
  LATE_NIGHT_THRESHOLD = 24
  BEDTIME_WARNING_THRESHOLD = 2


  ## Helpers ##

  def self.clear
    if Gem.win_platform?
      system("cls")
    else 
      system("clear")
    end
  end

  def self.exiting
    puts "Exiting...\n"
  end

  def self.press_any_key
    puts "\nPRESS ANY KEY\n".colorize( random_colour )
  end

  def self.print_error(error)
    puts "An error occurred: #{error}\n"
  end

  def self.dotted_separator
    puts " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  end

  def self.grackle_header(checkins = nil)
    clear
    puts '[' + Helper.power_month_indicator + Helper.speed_indicator + "]" +
         "   " +
         "Task".colorize(TASK_COLOR) + "Grackle".colorize(GRACKLE_COLOR) +
         "           " +
         Time.now.strftime('%A, %-d %B').colorize(DATE_COLOR) +
         "              " +
         determine_time_of_day.colorize(time_color(Time.now))

    dotted_separator
  end


  # REMINDERS AND SUGGESTIONS

  def self.general_and_fun_task_suggestions(tasks, checkins, friends, commlist, communities, engagelist)
    # re-calculate last checked-in for all tasks
    tasks.each do |key, task|
      task['last_checkin'] = Helper.last_checkin_for(key, checkins)
      task['hours_since_checkin'] = Helper.get_hours_since( task['last_checkin'] )
      task['hours_overdue'] = task['hours_since_checkin'] - task['frequency_hours']
      task['hours_overdue'] = 0 if task['hours_overdue'] < 0
      task['urgency'] = 0
      if !task['never_urgent']
        if task['hours_overdue'] > 336
          task['urgency'] = 5
        elsif task['hours_overdue'] > 168
          task['urgency'] = 4
        elsif task['hours_overdue'] > 72
          task['urgency'] = 3
        elsif task['hours_overdue'] > 48
          task['urgency'] = 2
        elsif task['hours_overdue'] > 24
          task['urgency'] = 1
        end
      end
    end

    # scan through all tasks, see which are furthest behind from target
    tasks_to_suggest = []
    available_fun_tasks = []
    fun_done = 0
    backlog_score = 0

    tasks.each do |key, task|
      if !task['dormant']
        if !['Vice', 'Work', 'Social'].include?(task['category'])
          if !task['no_nighttime'] || ![NIGHT, LATE_NIGHT].include?(determine_time_of_day)
            if !task['no_morning'] || ![MORNING].include?(determine_time_of_day)
              if task['category'] == 'Recreation' || task['fun']
                available_fun_tasks << task
                fun_done += Helper.checkins_today_of(key, checkins)
              elsif task['category'] != 'Food'
                if task['hours_overdue'] > 0
                  tasks_to_suggest << task
                  backlog_score += task['urgency']
                end
              end
            end
          end
        end
      end
    end

    # make task suggestions
    if tasks_to_suggest.size > 0
      puts "\nPositive activities [#{tasks_to_suggest.size}]:".colorize(:light_green)

      # make into 3 cols & sort
      first_col = []; second_col = []; third_col = []

      tasks_to_suggest.sort{ |a,b| b['urgency'] <=> a['urgency'] }.first(16).each_with_index do |task, i|
        if i < 5
          first_col << task
        elsif i < 10
          second_col << task
        else
          third_col << task
        end
      end

      # loop through first column & print additional cols at the same time
      first_col.each_with_index do |task, i|
        if third_col.size >= i + 1
          puts print_task_unit_with_color(first_col[i]) + print_task_unit_with_color(second_col[i]) + print_task_unit_with_color( third_col[i] )
        elsif second_col.size >= i + 1
          puts print_task_unit_with_color(first_col[i]) + print_task_unit_with_color(second_col[i])
        else
          puts print_task_unit_with_color(first_col[i])
        end
      end
    end

    # make fun suggestions
    second_col_offset = 21
    third_col_offset = 21

    # choose friend to nudge
    friendlist = []
    friends.each do |k, friend|
      friendlist << [friend['name'], friend['methods'], Helper.get_days_since( Helper.last_contacted_friend(k, commlist) )]
    end
    friendlist.sort!{ |a, b| b[2] <=> a[2] }
    selected_friend = friendlist.first(10).sample

    # choose Community to engage with
    community_list = []
    communities.each do |k, community|
      community_list << [community['name'], Helper.get_days_since( Helper.last_engaged_with_community(k, engagelist) )]
    end
    community_list.sort!{ |a, b| b[1] <=> a[1] }
    selected_community = community_list.first(4).sample


    if available_fun_tasks.size > 0
      puts ""
      puts ("Something fun:".ljust(second_col_offset + 3, ' ') +
            "Reach out by #{selected_friend[1].sample}:".ljust(third_col_offset + 3, ' ') ).colorize(:light_green) +
            "Check in with: ".colorize(:light_green)
            ## TODO + "Work on project:").colorize(:light_green)
      puts fun_spacer.colorize(random_colour) + available_fun_tasks.sample(1)[0]["name"].ljust(second_col_offset, ' ') +
           fun_spacer.colorize(random_colour) + "#{selected_friend[0]}".ljust(third_col_offset, ' ') +
           fun_spacer.colorize(random_colour) + "#{selected_community[0]}".ljust(third_col_offset, ' ')
    end

    puts ""

    puts "#{daily_fun_indicator(fun_done)}          #{gracklecoin_indicator}          #{backlog_warning(backlog_score)}"
  end

  def self.fun_spacer
    " ✓ ".colorize(:random_colour)
  end

  # gracklecoin in possession
  def self.gracklecoin_indicator
    bal = Helper.get_gracklecoin_balance
    if bal < 0
      bal_color = :light_red
    elsif bal < 10
      bal_color = :light_cyan
    elsif bal < 25
      bal_color = :light_magenta
    else
      bal_color = :light_yellow
    end
    "Gracklecoin: #{bal.to_s.colorize(bal_color)}"
  end

  # returns a warning based on severity of backlog
  def self.backlog_warning(score)
    base = "Backlog:"
    if score >= 35
      "#{base} #{score.to_s.colorize(:red)}  #{"* Emergency! *".colorize(:red)}"

    elsif score >= 30
      "#{base} #{score.to_s.colorize(:red)}  #{ "* Critical! *".colorize(:red) }"

    elsif score >= 25
      "#{base} #{score.to_s.colorize(:light_red)}  #{"* Warning! *".colorize(:light_red) }"

    elsif score >= 20
      "#{base} #{score.to_s.colorize(:light_red)}"

    elsif score >= 15
      "#{base} #{score.to_s.colorize(:yellow)}"

    elsif score >= 10
      "#{base} #{score.to_s.colorize(:cyan)}"

    elsif score >= 5
      "#{base} #{score}"

    else
      "#{base} #{score.to_s.colorize(:light_yellow)}"
    end
  end

  def self.daily_fun_indicator(fun_done)
    "Fun: " + (fun_done > 0 ? ("✓".colorize(:light_magenta) * fun_done) : '-')
  end


  # takes tasks in hash form
  def self.print_task_unit_with_color(task)
    maxcol_length = 23

    ('– ' + task["name"]).ljust(maxcol_length, ' ').colorize(
      [nil, DUE_COLOR, OVERDUE_COLOR, URGENT_COLOR, V_URGENT_COLOR, X_URGENT_COLOR][task["urgency"]]
    )
  end

  # late night but not super late
  def self.winddown_reminder(tasks)
    puts "Getting late... time to start winding down.".colorize(:red)
    moon_info
    puts "\nTry to check in before bed. #{graaak!}".colorize(:red)
  end

  # after 2am message
  def self.late_night_warning
    puts "Uh oh, it's super late! Try to get to bed soon.".colorize(:light_red)
    moon_info
  end

  # only in Normal and Crunch
  def self.billable_work_reminder(checkins)
    unless Helper.is_on_vacation? || Helper.is_in_slow_mode? || checkins.size < 3
      if !Helper.has_checked_in_key_today?('7', checkins)
        if [MORNING, AFTERNOON].include?(determine_time_of_day)
          puts "Feels good to get a jump on billable work. ".colorize(:magenta)
        else
          puts "You haven't done any billable work today. Try a mood check-up or a Work Hour.".colorize(:light_red)
        end
        return true

      elsif Helper.is_in_crunch? && Helper.checkins_today_of('7', checkins) < 2 && [AFTERNOON, EVENING].include?(determine_time_of_day)
        puts "Try doing some more billable work today! #{graaak!}".colorize(:light_red)
      elsif Helper.is_in_crunch? && Helper.checkins_today_of('7', checkins) < 3 && [EVENING, NIGHT].include?(determine_time_of_day)
        puts "#{graaak!}Night-time is best to do billable work.".colorize(:light_red)
      end
    end
    false
  end

  def self.mood_nudge(moodlist)
    if Helper.due_for_mood_checkup?(moodlist)
      puts "Try to do a quick mood check-in to make sure everything's okay.".colorize(MOOD_COLOR)
      true
    end
  end

  def self.exercise_nudge(tasks, checkins)
    if Helper.needs_exercise?(tasks, checkins)
      puts "It would feel good to do some exercise!".colorize(EXERCISE_COLOR)
      true
    end
  end

  def self.personal_work_reminder(checkins)
    if !Helper.has_checked_in_key_today?('e', checkins)
      puts "Try to work on business or a fun project today.".colorize(:cyan)
      true
    end
  end

  def self.initial_greeting
    puts "Welcome to TaskGrackle! #{graaak!}\n".colorize(MORNING_COLOR)
    puts "Keep your life on track by following a grackle's suggestions.\n".colorize(EXERCISE_COLOR)
    puts "Press 1 or Space Bar to check in the tasks you've done today.\n".colorize(SPRING_COLOR)
  end

  def self.secondary_greeting
    puts "Keep checking in during the day as you complete tasks.\n"
    puts "Earn Gracklecoin for work completed!.\n\n".colorize(MORNING_COLOR)
    puts "Periodically check in with your mood to make sure everything is okay.\n".colorize(MOOD_COLOR)
  end

  def self.third_greeting
    puts "Adjust Settings (-) to suit your speed of life and work.\n".colorize(EXERCISE_COLOR)
    puts "Edit the included " + ".json".colorize(SPRING_COLOR) + " files and " + "output.rb".colorize(SPRING_COLOR) + " to make TaskGrackle your own!\n"
    puts "Restart the program after making any edits.\n\n"
    puts "Press q to quit.\n".colorize(MOOD_COLOR)
  end

  def self.morning_first_greeting(tasks)
    puts "Good morning!\n".colorize(MORNING_COLOR)
    puts "Start the day off right by doing the foundational check-in tasks.\n".colorize(MORNING_COLOR)
    puts "Don't worry about work until those are done.\n".colorize(MORNING_COLOR) unless Helper.is_on_vacation?
    puts "#{graaak!}\n\n"
  end

  def self.meal_reminder(checkins)
    satiation_buffer = 3  # hours to be full after a meal

    if !Helper.has_checked_in_key_today?(['b', 'l'], checkins) && [MORNING, AFTERNOON].include?(determine_time_of_day)
      puts "Remember to eat some breakfast!".colorize(MORNING_COLOR)
      return true

    elsif !Helper.has_checked_in_key_today?(['l', 'd'], checkins) && [AFTERNOON, EVENING].include?(determine_time_of_day)
      if Helper.get_hours_since(Helper.last_checkin_for('b', checkins)) >= satiation_buffer
        puts "Remember to eat lunch, even though you may not be hungry!".colorize(AFTERNOON_COLOR)
        return true
      end

    elsif !Helper.has_checked_in_key_today?('d', checkins) && [EVENING, NIGHT].include?(determine_time_of_day)
      if Helper.get_hours_since(Helper.last_checkin_for('l', checkins)) >= satiation_buffer
        puts "Remember to eat a good dinner!".colorize(EVENING_COLOR)
        return true
      end
    end
    false
  end

  def self.exercise_reminder(tasks, checkins)
    if Helper.needs_exercise?(tasks, checkins)
      puts "If you get a chance, it would feel good to do exercise.".colorize(EXERCISE_COLOR)
      return true
    end
  end

  def self.compliance_warning(checkins)
    case Helper.checkins_in_last_24_hours(checkins)
    when 0
      puts "You didn't check in at all for the last 24 hours. #{graaak!}"
    when 1
      puts "#{graaak!}Low TaskGrackle compliance. Try to check in more!"
    end
  end

  def self.beginning_of_day_productivity_tips
    puts "Put on headphones and make a to-do list!".colorize(:light_green)
  end


  ## Screens ##

  def self.splash
    clear
    puts "wolfOS".colorize(:magenta) + " & " + "Mirth Turtle Media".colorize(EXERCISE_COLOR) + " present:"
    puts " _            _      ".colorize(TASK_COLOR) + "                  _    _      ".colorize(GRACKLE_COLOR) + "\n"
    puts "| |_ __ _ ___| | __".colorize(TASK_COLOR) + "__ _ _ __ __ _  ___| | _| | ___ ".colorize(GRACKLE_COLOR) + "\n"
    puts "| __/ _` / __| |/ /".colorize(TASK_COLOR) + " _` | '__/ _` |/ __| |/ / |/ _ \\".colorize(GRACKLE_COLOR) + "\n"
    puts "| || (_| \\__ \\   <".colorize(TASK_COLOR) + " (_| | | | (_| | (__|   <| |  __/".colorize(GRACKLE_COLOR) + "\n"
    puts " \\__\\__,_|___/_|\\_\\".colorize(TASK_COLOR) + "__, |_|  \\__,_|\\___|_|\\_\\_|\\___|".colorize(GRACKLE_COLOR) + "\n"
    puts "                  ".colorize(TASK_COLOR) + "|___/       DAY MANAGER ".colorize(GRACKLE_COLOR)
    puts ""
    puts "    \"An annoying grackle tells you what to do\"\n\n\n".colorize(:light_blue)
    puts "             # press SPACE to begin #\n\n".colorize(TASK_COLOR)
  end

  # MAIN INTERFACE
  def self.main_interface(tasks, checkins, moodlist, seasons, friends, commlist, communities, engagelist)
    grackle_header(checkins)

    # Welcome messages
    if checkins.size == 0
      initial_greeting
    elsif checkins.size == 1 && moodlist.size == 0
      secondary_greeting
    elsif checkins.size == 1 && moodlist.size == 1
      third_greeting

    # Morning greeting
    elsif !Helper.checked_in_today(checkins) && [MORNING, AFTERNOON].include?(determine_time_of_day)
      morning_first_greeting(tasks)

    # TASKGRACKLE NIIIIGHTS
    elsif determine_time_of_day == LATE_NIGHT
      if Time.now.hour < BEDTIME_WARNING_THRESHOLD
        winddown_reminder(tasks)
      else
        late_night_warning
      end

    # GENERAL DAY MANAGEMENT
    else
      if Helper.total_checkins_today(checkins) == 1 && [MORNING, AFTERNOON].include?(determine_time_of_day)
        beginning_of_day_productivity_tips
      elsif Helper.in_annoying_mode?
        compliance_warning(checkins)
      end

      # Important nudges - top area
      if !meal_reminder(checkins)
        season_transition_tips(seasons)
        unless billable_work_reminder(checkins)
          unless mood_nudge(moodlist)
            unless exercise_nudge(tasks, checkins)
              personal_work_reminder(checkins)
            end
          end
        end
      end

      # Normal daily backlog
      general_and_fun_task_suggestions(tasks, checkins, friends, commlist, communities, engagelist)
    end

    dotted_separator

    t1 = "1  Task Check-in        ".colorize(checkins.size == 0 ? SPRING_COLOR : nil)
    t2 = "2  Mood Checkup         ".colorize(Helper.total_checkins_today(checkins) > 0 && Helper.due_for_mood_checkup?(moodlist) ? MOOD_COLOR : nil)
    t3 = "3  Exercise".colorize(Helper.needs_exercise?(tasks, checkins) ? EXERCISE_COLOR : nil)
    t4 = "4  Plan Day             ".colorize(Helper.total_checkins_today(checkins) == 1 && [MORNING, AFTERNOON].include?(determine_time_of_day) ? MORNING_COLOR : nil)
    t5 = "5  Work Hour            "
    t6 = "6  Groceries            "
    t7 = "7  Friends & Family     "
    t8 = "8  Communities          "
    t9 = "9  Sleep Mode           "
    t0 = "-  Settings             "
    tc = "0  History              "
    td = "+  Debug                "

    puts "#{t1}#{t2}#{t3}\n"
    puts "#{t4}#{t5}#{t6}\n"
    puts "#{t7}#{t8}#{t9}\n"
    puts "#{t0}#{tc}#{td}\n"
  end


  ## CHECK-IN

  # re-displays the check-in screen with the current tasks obj
  def self.current_check_in(tasks, checkins)
    grackle_header
    # clear; dotted_separator

    taskline_length = 19 # task name including ...s
    taskcol_spacer  = " " * 5  # blank space between columns

    first_col  = []
    second_col = []
    third_col  = []

    no_checkins_today = Helper.total_checkins_today(checkins) == 0
    no_highlight = checkins.size == 0

    # organize into columns
    task_counter = 0
    tasks_toggled = 0
    tasks.each do |key, task|
      if Helper.get_settings_from_json_or_create[:vice] > 0 || task["category"] != "Vice"
        # determine if task is toggled or not
        tasks_toggled += 1 if task["toggled"]
        its_late = determine_time_of_day == LATE_NIGHT
        morning_highlight = (no_checkins_today && task["morning"] && !its_late && !no_highlight) ? MORNING_COLOR : nil
        night_highlight = its_late && task["winddown"] && !no_highlight ? NIGHT_COLOR : nil
        always_highlight = task["always"] ? WATER_COLOR : nil

        display_key = task["toggled"] ? '✓'.colorize(morning_highlight ? :light_magenta : MORNING_COLOR) : key
        taskline = "#{task["name"].ljust(taskline_length, ".")}".colorize(morning_highlight || night_highlight || always_highlight)

        if task_counter < 18
          first_col << (taskline + display_key)
        elsif task_counter < 36
          second_col << (taskline + display_key)
        else
          third_col << (taskline + display_key)
        end
        task_counter += 1
      end
    end

    # loop through first column & print additional cols at the same time
    first_col.each_with_index do |task, i|
      if third_col.size >= i + 1
        puts first_col[i] + taskcol_spacer + second_col[i] + taskcol_spacer + third_col[i]
      elsif second_col.size >= i
        puts first_col[i] + taskcol_spacer + second_col[i]
      else
        puts first_col[i]
      end
    end

    dotted_separator
    puts "# SPACE to #{tasks_toggled > 0 ? 'finish' : 'cancel'} #{tasks_toggled > 0 ? '– EQUALS to backdate ' : ''}#"
  end

  def self.completed_checkin_screen
    grackle_header
    if determine_time_of_day == LATE_NIGHT
      puts "Have a good sleep!".colorize(:light_red)
      puts "Prep morning snack, lock doors, close windows, etc.\n".colorize(:red)
      puts "Remember to take pills & set an alarm.\n".colorize(:red)
    else
      puts "Check-in Complete\n".colorize( random_colour )
      puts "#{graaak!}\n\n"
    end

    dotted_separator
    puts "# press SPACE to exit #\n\n"
  end

  def self.prompt_for_backdate
    puts "Backdate how many days? 1-9 "
  end


  ## WORK HOUR

  # show checklist & reco's
  def self.work_hour_prep
    grackle_header
    work_location = ['Standing desk', 'Armchair', 'The counter', 'The table', 'The sofa'].sample

    puts "Prepare for Work Hour:\n".colorize(:light_green)
    puts "- Put on headphones".colorize(:light_green)
    puts "- Phone to charging station"
    puts "- Water in thermos"
    puts "- Set up location: #{work_location}"
    puts "- Set goal"
    puts "- Use bathroom"
    dotted_separator
    puts "* press 7 to start *".colorize(:light_green)
    puts "# press SPACE to cancel #\n\n"
  end

  def self.ongoing_work_hour
    grackle_header
    puts "Work Hour has begun.\n".colorize(:light_green)
    puts "- Start stopwatch\n\n"
    puts "#{graaak!}\n\n".colorize(random_colour)

    dotted_separator
    puts "# press SPACE to finish #\n\n"
  end

  def self.completed_work_hour
    grackle_header
    puts "Work Hour Complete.".colorize( random_colour )
    puts "Billable work logged.".colorize( random_colour )
    puts ""
    puts "Enjoy a snack and try to do something relaxing or fun.\n\n"

    dotted_separator
    puts "# press SPACE to finish #\n\n"
  end


  ## HISTORY / STATS

  def self.history_index(tasks, checkins)
    grackle_header
    puts "History\n\n"

    checkins.reverse[0..7].each do |checkin_array|
      checkin_keys = checkin_array[1].chars
      checkin_task_names = []
      checkin_keys.each do |checkin_key|
        if tasks[checkin_key]
          checkin_task_names << tasks[checkin_key]['name']
        else
          checkin_task_names << '[removed]'
        end
      end

      puts "#{checkin_array[0].strftime('%a %b %d %I:%M %p').colorize(time_color(checkin_array[0]))} #{checkin_task_names.join(", ")}"
    end
    dotted_separator
    puts "# press keys to filter #".colorize(:light_blue)
    puts "# press SPACE to exit #\n\n"
  end

  # print last checkin dates for that task
  def self.filtered_history(selected, tasks, checkins)
    max_dates = 14

    grackle_header
    puts tasks[selected]['name']
    puts ""

    checkins.reverse.each do |checkin|
      if checkin[1].chars.include?(selected)
        puts checkin[0].strftime('%a %b %d %I:%M %p').colorize(time_color(checkin[0]))
        max_dates -= 1
      end
      break if max_dates <= 0
    end
    dotted_separator
    puts "# press keys to filter #".colorize(:light_blue)
    puts "# press - to clear filter #".colorize(:red)
    puts "# press SPACE to exit #\n\n"
  end


  ## GROCERY PREP

  # send to watch later
  def self.grocery_prep_screen(essentials)
    grackle_header
    grocery_col_length = 25

    # split into 3 columns
    cols = [[],[],[]]
    count = 0
    essentials.each do |key, gc|
      if count <= (essentials.size / 3)
        cols[0] << gc['name']
      elsif count <= ((essentials.size / 3) * 2) + 1
        cols[1] << gc['name']
      else
        cols[2] << gc['name']
      end
      count += 1
    end

    # loop through first column & print additional cols at the same time
    cols[0].each_with_index do |task, i|
      if cols[2].size >= i + 1
        puts cols[0][i].ljust(grocery_col_length) + cols[1][i].ljust(grocery_col_length) + cols[2][i]
      elsif cols[1].size >= i
        puts cols[0][i].ljust(grocery_col_length) + cols[1][i]
      else
        puts cols[0][i]
      end
    end

    puts ""
    dotted_separator
    puts "# press SPACE to exit #\n\n"
  end

  def self.mood_and_habit_checkup_screen(habits)
    grackle_header
    puts "How are you feeling?\n".colorize(:light_magenta)

    habitline_length = 25 # habit name including ...s
    habitcol_spacer  = " " * 6  # blank space between columns

    first_col  = []
    second_col = []

    # organize into columns
    habit_counter = 0
    habits_toggled = 0
    habits.each do |key, habit|
      # determine if habit is toggled or not
      habits_toggled += 1 if habit["toggled"]
      display_key = habit["toggled"] ? '✓'.colorize(:light_cyan) : key
      habitline = "#{habit["name"].ljust(habitline_length, ".")}#{display_key}"

      if habit_counter <= (habits.size / 2)
        first_col << habitline
      else
        second_col << habitline
      end
      habit_counter += 1
    end

    # loop through first column & print additional cols at the same time
    first_col.each_with_index do |habit, i|
      if second_col[i]
        puts first_col[i] + habitcol_spacer + second_col[i]
      else
        puts first_col[i]
      end
    end
    puts ""

    dotted_separator
    puts "# press SPACE to #{habits_toggled > 0 ? 'finish' : 'cancel'} #\n"
  end

  def self.completed_habit_checkin(habits)
    grackle_header

    puts "Checking in with TaskGrackle is self-care! #{graaak!}\n".colorize(MOOD_COLOR)

    # recommend solutions for the toggled habits
    habits.each do |k, habit|
      if habit["toggled"]
        puts habit["solution"].colorize([:green, :light_green, :magenta].sample)
      end
    end
    puts ""
    puts "# press SPACE to continue #\n"
  end

  # SETTINGS
  def self.settings_screen(settings)
    grackle_header
    puts "– Work Speed –              Let TaskGrackle hassle you about work."
    puts "v   Vacation".colorize(settings[:speed] == 0 ? :magenta : nil)
    puts "s   Slow".colorize(settings[:speed] == 1 ? :light_blue : nil)
    puts "n   Normal".colorize(settings[:speed] == 2 ? :green : nil)
    puts "c   Crunch".colorize(settings[:speed] == 3 ? :red : nil)
    puts ""

    puts "– Annoying Mode #{Helper.in_annoying_mode? ? 'ON '.colorize(SPRING_COLOR) : 'OFF'.colorize(MOOD_COLOR)} –       TaskGrackle can be more or less annoying."
    puts "a   Toggle"
    puts ""

    puts "– Vice Management #{Helper.in_vicetracking_mode? ? 'ON '.colorize(EXERCISE_COLOR) : 'OFF'.colorize(MOOD_COLOR)} –     Use TaskGrackle to manage or overcome a vice."
    puts "t   Toggle"
    puts ""

    puts "\n\n# press SPACE to return #\n"
  end

  # DAY PLANNING
  def self.dayplanning_screen
    grackle_header
    puts "Make a plan for the day:\n".colorize(MORNING_COLOR)

    puts "- Put on headphones".colorize(:light_green)
    puts "- Estimate doable work & block off time" if !Helper.is_on_vacation?
    puts "- Plan errands & cycling"
    puts "- Plan exercise session"
    puts "- Plan nap"
    puts "- Make list of people to contact & when"

    puts "\nDo the worst thing first! #{graaak!}\n".colorize(MORNING_COLOR)

    puts "\n# press SPACE to return #\n"
  end

  # RELAXATION
  def self.relaxation_area
    grackle_header
    puts "                   +           +                       +           +     "
    puts "   +                                            +                        ".colorize(:blue)
    puts "                                                               +         ".colorize(:light_cyan)
    puts "         +                                   +                           ".colorize(:cyan)
    puts "                    +                                   +                ".colorize(:light_blue)
    puts "                                  +                                   +  "
    puts "                           +                                             ".colorize(:blue)
    puts "           +                                   +                         ".colorize(:light_cyan)
    puts "                                                                         ".colorize(:cyan)
    puts "                        +          +                        +          + "
    puts "               +                                   +                     ".colorize(:light_blue)
    puts "    +                         +         +                         +      ".colorize(:light_cyan)
    puts "                                                        +                ".colorize(:blue)
    puts "        +                           +                          +         "
    puts "                           +                                             ".colorize(:light_blue)
    puts "           +                                   +                         ".colorize(:light_cyan)
    puts "                               +                             +           ".colorize(:cyan)
    puts "\n# press SPACE to return #\n".colorize(:blue)
  end


  ## FRIENDS & FAMILY

  def self.friends_and_family_screen(friends, commlist)
    grackle_header

    # determine score/band
    main_score = 0
    isolation_score = 0
    total_friends = friends.size
    friends.each do |key, friend|
      main_score += main_score_for_friend(key, commlist)
      isolation_score += isolation_score_for_friend(key, commlist)
    end

    isolation_part = total_friends > 10 ? "[#{isolation_score}: #{band_for(isolation_score)}]" : ""
    puts "Friends & Family – #{main_score}/#{total_friends} #{isolation_part}"
    puts ""
    friendline_length = 19 # friend name including ...s
    friendcol_spacer  = " " * 5  # blank space between columns

    first_col  = []
    second_col = []
    third_col  = []

    # organize into columns
    friend_counter = 0
    friends.each do |key, friend|
      friendline = friend["name"].ljust(friendline_length, ".").colorize(color_for_friend(key, commlist))

      if friend_counter <= (friends.size / 3)
        first_col << (friendline + key)
      elsif friend_counter <= ((friends.size / 3) * 2) + 1
        second_col << (friendline + key)
      else
        third_col << (friendline + key)
      end
      friend_counter += 1
    end

    # loop through first column & print additional cols at the same time
    first_col.each_with_index do |friend, i|
      if third_col.size >= i + 1
        puts first_col[i] + friendcol_spacer + second_col[i] + friendcol_spacer + third_col[i]
      elsif second_col.size >= i + 1
        puts first_col[i] + friendcol_spacer + second_col[i]
      else
        puts first_col[i]
      end
    end

    puts "\n# press SPACE for menu #\n"
  end

  def self.color_for_friend(friendkey, commlist)
    last_contact = Helper.last_contacted_friend(friendkey, commlist) || Time.now - (150 * 86400)  ## high default
    case Helper.get_days_since(last_contact).floor
    when 0
      :light_yellow
    when 1..7
      :light_cyan
    when 8..21
      :yellow
    when 22..45
      :cyan
    when 45..90
      :light_red
    else
      :red
    end
  end

  def self.color_for_community(communitykey, engagelist)
    last_contact = Helper.last_engaged_with_community(communitykey, engagelist) || Time.now - (150 * 86400)  ## high default
    case Helper.get_days_since(last_contact).floor
    when 0
      :light_yellow
    when 1..7
      :light_cyan
    when 8..21
      :yellow
    when 22..45
      :cyan
    when 45..90
      :light_red
    else
      :red
    end
  end

  def self.main_score_for_friend(friendkey, commlist)
    last_contact = Helper.last_contacted_friend(friendkey, commlist) || Time.now - (150 * 86400)  ## high default
    if Helper.get_days_since(last_contact) > 90
      0
    else
      1
    end
  end

  def self.isolation_score_for_friend(friendkey, commlist)
    last_contact = Helper.last_contacted_friend(friendkey, commlist) || Time.now - (150 * 86400)  ## high default
    case Helper.get_days_since(last_contact).floor
    when 0
      0
    when 1..7
      1
    when 8..21
      2
    when 22..45
      3
    when 45..90
      5
    else
      10
    end
  end

  def self.band_for(isolation_score)
    if isolation_score > 400
      "extremely isolated"
    elsif isolation_score > 350
      "very isolated"
    elsif isolation_score > 300
      "quite isolated"
    elsif isolation_score > 250
      "somewhat isolated"
    elsif isolation_score > 200
      "a bit isolated"
    elsif isolation_score > 150
      "somewhat connected"
    elsif isolation_score > 100
      "quite connected"
    elsif isolation_score > 50
      "very connected"
    else
      "extremely connected"
    end
  end


  ## COMMUNITIES

    def self.communities_screen(communities, engagements)
    grackle_header

    puts "Communities"
    puts ""
    communityline_length = 28 # community name including ...s
    communitycol_spacer  = " " * 5  # blank space between columns

    first_col  = []
    second_col = []

    # organize into columns
    community_counter = 0
    communities.each do |key, community|
      communityline = community["name"].ljust(communityline_length, ".").colorize(color_for_community(key, engagements))

      if community_counter <= (communities.size / 2)
        first_col << (communityline + key)
      else
        second_col << (communityline + key)
      end
      community_counter += 1
    end

    # loop through first column & print additional cols at the same time
    first_col.each_with_index do |community, i|
      if second_col.size >= i + 1
        puts first_col[i] + communitycol_spacer + second_col[i]
      else
        puts first_col[i]
      end
    end

    puts "\n# press SPACE for menu #\n"
  end

  ## EXERCISE

  def self.exercise_screen(exercises, current_exercises, exercises_done, choice=nil)
    grackle_header

    n_done = exercises_done.size

    if n_done == 0
      puts "Put on comfortable clothes and have a fun session!\n".colorize(EXERCISE_COLOR)
    else
      puts "✓".colorize(:light_green) * exercises_done.size
      puts ""
    end

    current_exercises.each_with_index do |key, i|
      puts "#{i + 1}: #{exercises[key]['name'].colorize(choice && choice == (i + 1).to_s ? :light_yellow : :green)}"
      puts "  " + exercises[key]['method']
      puts ""
    end

    puts "# press SPACE to return #\n"
  end

  ## SEASONS

  def self.season_transition_tips(seasons)
    if Time.now.day == 1
      seasons.each do |k, season|
        if season['months'][0] == Time.now.month
          puts season['starting_tips'].sample
        end
      end
    elsif Time.now.day == 15
      seasons.each do |k, season|
        # midpoints of seasons occur in the following month from start month
        if season['months'][0] == Time.now.month - 1
          puts season['midpoint_tips'].sample
        end
      end
    end
  end

  ## Thought collector stuff

  def self.type_something
    puts "Ready. Type 'x' or 'q' to stop.\n\n".colorize(random_colour)
  end

  def self.save_successful
    puts "✓\n".colorize(random_colour)
  end

  ## DEBUG

  def self.debug_screen(tasks)
    grackle_header

    puts "If you're hacking TaskGrackle, here is what each color code looks like:"
    puts "red".colorize(:red)
    puts "light_red".colorize(:light_red)
    puts "green".colorize(:green)
    puts "light_green".colorize(:light_green)
    puts "yellow".colorize(:yellow)
    puts "light_yellow".colorize(:light_yellow)
    puts "light_blue".colorize(:light_blue)
    puts "magenta".colorize(:magenta)
    puts "light_magenta".colorize(:light_magenta)
    puts "cyan".colorize(:cyan)
    puts "light_cyan".colorize(:light_cyan)
    # we don't use :blue because it's too dark on our black screen

    possible_chars = ("A".."Z").to_a +
                     ("a".."z").to_a +
                     ("0".."9").to_a +
                     ['!','@','#','$','%','^','&','*','(',')','-','+']
    puts "\nAvailable task keys: " + (possible_chars - tasks.keys).join(" ") + "\n"

    dotted_separator
    puts "# press SPACE to exit #"
  end

  private

    def self.graaak!
      Helper.get_settings_from_json_or_create[:annoying] > 0 ? "Graaak! " : ""
    end

    # borrowed from ActionView
    def self.word_wrap(text, line_width: 80, break_sequence: "\n")
      text.split("\n").collect! do |line|
        line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1#{break_sequence}").strip : line
      end * break_sequence
    end

    def self.random_colour
      colours = [:red, :light_red, :green, :light_green, :yellow, :light_yellow, :light_blue, :magenta, :light_magenta, :cyan, :light_cyan]
      colours[ Random.new.rand(colours.length) ]
    end

    def self.determine_time_of_day
      the_hour = Time.now.hour
      if the_hour < MORNING_THRESHOLD
        LATE_NIGHT
      elsif the_hour < AFTERNOON_THRESHOLD
        MORNING
      elsif the_hour < EVENING_THRESHOLD
        AFTERNOON
      elsif the_hour < NIGHT_THRESHOLD
        EVENING
      else
        NIGHT
      end
    end

    def self.time_color(time)
      determine_time_color_by_hour(time.hour)
    end

    def self.determine_time_color_by_hour(hour)
      if hour < MORNING_THRESHOLD
        :red
      elsif hour < AFTERNOON_THRESHOLD
        :light_yellow
      elsif hour < EVENING_THRESHOLD
        :green
      elsif hour < NIGHT_THRESHOLD
        :cyan
      else
        :yellow
      end
    end

    def self.moon_info
      puts "\nQuerying moon service...".colorize(DARKMOON_COLOR)
      begin
        timestamp = Time.new.to_i

        response = HTTParty.get("https://api.farmsense.net/v1/moonphases/?d=#{timestamp}", verify: false)
        resp = JSON.parse( response.body )[0]

        # parse out data
        if resp['Error'] == 0
          moon_name = resp['Moon'][0]
          phase = resp['Phase']
          puts "The #{moon_name || 'moon'} is #{phase} tonight.".colorize(BRIGHTMOON_COLOR)
        else
          puts "Error getting moon info... hopefully it's OK.".colorize(BRIGHTMOON_COLOR)
        end
      rescue => e
        puts "Unexpected error on moon call.".colorize(BRIGHTMOON_COLOR)
        puts e
      end
    end

end
