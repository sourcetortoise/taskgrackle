#!/usr/bin/ruby
# TASKGRACKLE - Day Manager

require_relative 'taskgrackle/input'
require_relative 'taskgrackle/output'
require_relative 'taskgrackle/helper'

require 'json'
require 'csv'
require 'time'

class Taskgrackle

  def self.activate
    tasks       = get_tasks_from_json
    habits      = get_habits_from_json
    checkins    = get_checkins_from_csv
    moodlist    = get_moodlist_from_csv
    commlist    = get_comms_from_csv
    essentials  = get_essentials_from_json
    exercises   = get_exercises_from_json
    friends     = get_friends_from_json
    seasons     = get_seasons_from_json
    communities = get_communities_from_json
    engagements = get_engagements_from_csv
    settings    = Helper.get_settings_from_json_or_create

    print_splash_screen

    # MAIN INTERFACE
    Output.main_interface(tasks, checkins, moodlist, seasons, friends, commlist, communities, engagements)

    input = Input.get
    while !Input.break.include?(input)

      ## TASK CHECK-IN ##
      if Input.checkin.include?(input)
        checkin_initiated_at = Time.now
        Output.current_check_in(tasks, checkins)

        checkin_input = Input.get
        while ![Input.space, Input.backdate].include?(checkin_input) # check-in with space bar, backdate w/ delete
          # toggle appropriate item & redisplay list
          if tasks[checkin_input]
            tasks[checkin_input]["toggled"] = !!!tasks[checkin_input]["toggled"]
          end
          Output.current_check_in(tasks, checkins)

          checkin_input = Input.get
        end

        # Backdating
        if checkin_input == Input.backdate
          # Prompt for days back
          Output.prompt_for_backdate

          backdate_input = Input.get
          while !Input.integers.include?(backdate_input)
            backdate_input = Input.get
          end
          checkin_initiated_at = checkin_initiated_at - (backdate_input.to_i * 86400)
        end

        # send tasks to output file [or server] if any tasks checked
        if save_checkin(tasks, checkins, checkin_initiated_at)
          Output.completed_checkin_screen
          Helper.update_last_interacted

          # reset the tasks toggles
          tasks.each do |key, task|
            task["toggled"] = false
          end

          Input.space_to_continue
        end



      ## WORK HOUR ##
      elsif Input.work_hour.include?(input)
        Output.work_hour_prep

        did_work = false
        workhour_input = Input.get
        while workhour_input != Input.space && !did_work  # cancel work hour with space bar
          if workhour_input == Input.money_key
            Helper.place_squawkblocker

            Output.ongoing_work_hour
            Input.space_to_continue

            log_billable_work(checkins)
            did_work = true

            Helper.remove_squawkblocker
            Helper.update_last_interacted

            Output.completed_work_hour
            Input.space_to_continue
          else
            workhour_input = Input.get
          end
        end


      ## HISTORY SCREEN ##
      elsif input == Input.history
        Output.history_index(tasks, checkins)

        history_input = Input.get
        while !Input.space.include?(history_input)
          if tasks.keys.include?(history_input)
            # switch to filter
            Output.filtered_history(history_input, tasks, checkins)
          elsif Input.nofilter_key.include?(history_input)
            # re-show index
            Output.history_index(tasks, checkins)
          end

          history_input = Input.get
        end

      ## GROCERY PREP ##
      elsif input == Input.grocery_prep
        Output.grocery_prep_screen(essentials)
        Input.space_to_continue


      ## MOOD CHECKUP ##
      elsif Input.mood_and_habit_checkup.include? (input)
        Output.mood_and_habit_checkup_screen(habits)

        checkup_input = Input.get
        while !Input.space.include?(checkup_input)
          # toggle appropriate item & redisplay habit list
          if habits[checkup_input]
            habits[checkup_input]["toggled"] = !!!habits[checkup_input]["toggled"]
          end
          Output.mood_and_habit_checkup_screen(habits)

          checkup_input = Input.get
        end

        # send habits to output file [or server] if any habits checked & displays recommendations
        if save_habit_checkup(habits, moodlist)
          Output.completed_habit_checkin(habits)
          Helper.update_last_interacted

          # reset the habits toggles
          habits.each do |key, habit|
            habit["toggled"] = false
          end

          Input.space_to_continue
        end


      ## SETTINGS SCREEN ##
      elsif Input.settings.include?(input)
        Output.settings_screen(settings)

        settings_input = Input.get
        while !Input.settings_space.include?(settings_input)
          if Input.speed_options.include?(settings_input)
            # write appropriate setting
            settings = Helper.set_speed(settings_input)
          elsif Input.annoying_key == settings_input
            # toggle annoying mode
            Helper.set_setting(:annoying, Helper.in_annoying_mode? ? 0 : 1 )
          elsif Input.vice_key == settings_input
            # toggle vice-chip mode
            Helper.set_setting(:vice, Helper.in_vicetracking_mode? ? 0 : 1 )
          end

          # re-show screen
          Output.settings_screen(settings)
          settings_input = Input.get
        end


      ## DAY PLANNING
      elsif input == Input.dayplan_key
        Output.dayplanning_screen
        Input.space_to_continue


      ## RELAXATION
      elsif input == Input.relaxation_key
        Helper.place_squawkblocker

        Output.relaxation_area
        Input.space_to_continue

        Helper.remove_squawkblocker


      ## FRIENDS & FAMILY
      elsif input == Input.friends_key
        Output.friends_and_family_screen(friends, commlist)

        selected_friend = nil
        friend_input = Input.get
        while !Input.space.include?(friend_input)
          if friends.keys.include?(friend_input)
            # switch to friend
            selected_friend = friend_input

            save_friend_contact(selected_friend, commlist)
            Helper.update_last_interacted

            # re-show index
            Output.friends_and_family_screen(friends, commlist)
            selected_friend = nil
          end

          friend_input = Input.get
        end


      ## EXERCISE MACHINE
      elsif input == Input.exercise_key
        Helper.place_squawkblocker

        exercises_done = []
        current_exercise_keys = exercises.keys.shuffle.sample(6)
        Output.exercise_screen(exercises, current_exercise_keys, exercises_done)

        exercise_input = Input.get
        while !Input.space.include?(exercise_input)
          if Input.exercise_choices.include?(exercise_input)
            # identify the chosen exercise
            chosen_index = exercise_input.to_i - 1
            chosen_key = current_exercise_keys[chosen_index]
            chosen_exercise = exercises[chosen_key]

            # replace exercise with new from main array
            possible_new_exercises = exercises.keys - current_exercise_keys
            current_exercise_keys[chosen_index] = possible_new_exercises.sample
            exercises_done << chosen_exercise['type']

            Output.exercise_screen(exercises, current_exercise_keys, exercises_done, exercise_input)
          end

          exercise_input = Input.get
        end

        log_exercise(checkins, exercises_done.uniq) if exercises_done.size > 0
        Helper.remove_squawkblocker


      ### COMMUNITIES
      elsif input == Input.communities_key

        Output.communities_screen(communities, engagements)

        selected_community = nil
        community_input = Input.get
        while !Input.space.include?(community_input) || (Input.space.include?(community_input) && selected_community)
          if communities.keys.include?(community_input)
            # mark community as engaged-with
            selected_community = community_input
            save_community_engagement(selected_community, engagements)
            Helper.update_last_interacted

            # re-show the page
            Output.communities_screen(communities, engagements)
            selected_community = nil
          end

          community_input = Input.get
        end


      ## SECRET DEBUG SCREEN ##
      elsif input == Input.debug_menu
        Output.debug_screen(tasks)
        Input.space_to_continue
      end

      # Back to main menu; get next input
      Output.main_interface(tasks, checkins, moodlist, seasons, friends, commlist, communities, engagements)
      input = Input.get
    end

    Output.clear
    Output.exiting

  end


  private

    def self.print_splash_screen
      Output.splash
      Input.space_to_continue
    end

    def self.get_tasks_from_json
      file = File.read('./data/tasks.json')
      JSON.parse(file)
    end

    def self.get_essentials_from_json
      file = File.read('./data/essentials.json')
      JSON.parse(file)
    end

    def self.get_exercises_from_json
      file = File.read('./data/exercises.json')
      JSON.parse(file)
    end

    def self.get_seasons_from_json
      file = File.read('./data/seasons.json')
      JSON.parse(file)
    end

    def self.get_friends_from_json
      file = File.read('./data/friends.json')
      JSON.parse(file)
    end

    def self.get_communities_from_json
      file = File.read('./data/communities.json')
      JSON.parse(file)
    end

    def self.get_habits_from_json
      file = File.read('./data/habits.json')
      JSON.parse(file)
    end

    def self.get_checkins_from_csv
      checkins = []
      if File.file?("./data/checkins.csv")
        CSV.foreach("./data/checkins.csv") do |row|
          checkins << [Time.parse(row[0]), row[1]]
        end
      end
      checkins
    end

    def self.get_moodlist_from_csv
      moodlist = []
      if File.file?("./data/mood.csv")
        CSV.foreach("./data/mood.csv") do |row|
          moodlist << [Time.parse(row[0]), row[1]]
        end
      end
      moodlist
    end

    def self.get_comms_from_csv
      commlist = []
      if File.file?("./data/comms.csv")
        CSV.foreach("./data/comms.csv") do |row|
          commlist << [Time.parse(row[0]), row[1]]
        end
      end
      commlist
    end

    def self.get_engagements_from_csv
      engagelist = []
      if File.file?("./data/engagements.csv")
        CSV.foreach("./data/engagements.csv") do |row|
          engagelist << [Time.parse(row[0]), row[1]]
        end
      end
      engagelist
    end

    def self.save_checkin(tasks, checkins, initiated_at)
      # collect the keys from the toggled tasks
      task_string = tasks.select{|k,v| v["toggled"]}.collect{|k,v| k}.join("")

      if !task_string.empty?
        # if no recent checkin, or not a backdate
        if Helper.minutes_since_last_checkin(checkins) >= 5 || initiated_at < Time.now - 5000
          # new checkin in file
          new_checkin = [initiated_at, task_string]
          CSV.open("./data/checkins.csv", "a") do |csv|
            csv << new_checkin
          end

          # keep the checkins array current
          checkins << new_checkin
        else
          # go to last line of checkins file
          last_line = 0
          file = File.open('./data/checkins.csv', 'r+')
          file.each { last_line = file.pos unless file.eof?}
          file.seek(last_line, IO::SEEK_SET)

          # re-write the last line with the new checkin data
          new_checkin_data = (checkins.last[1] + task_string).chars.uniq.join
          file.write(checkins.last[0].to_s + "," + new_checkin_data + "\n")
          file.close

          # keep the checkins array current
          checkins.last[1] = new_checkin_data
        end

        # do gracklecoin transactions
        current_balance = Helper.get_gracklecoin_balance
        task_string.chars.each do |task_key|
          current_balance += tasks[task_key]['coins']
        end
        Helper.update_gracklecoin_balance( current_balance )

        true
      else
        false # no checkin saved if no tasks checked off
      end
    end

    def self.save_habit_checkup(habits, moodlist)
      # collect the keys from the toggled habits
      habit_string = habits.select{|k,v| v["toggled"]}.collect{|k,v| k}.join("")

      if !habit_string.empty?
        new_habit_checkup = [Time.now, habit_string]
        CSV.open("./data/mood.csv", "a") do |csv|
          csv << new_habit_checkup
        end
        # keep the mood array current
        moodlist << new_habit_checkup
        true
      else
        false # no checkup saved if no habits checked off
      end
    end

    def self.log_billable_work(checkins)
      billable_checkin = [Time.now, '7']
      CSV.open("./data/checkins.csv", "a") do |csv|
        csv << billable_checkin
      end
      checkins << billable_checkin
    end

    def self.log_exercise(checkins, done)
      exercise_checkin = [Time.now, done.join]
      CSV.open("./data/checkins.csv", "a") do |csv|
        csv << exercise_checkin
      end
      checkins << exercise_checkin
    end

    def self.save_friend_contact(friend_key, commlist)
      new_comm = [Time.now, friend_key]
      CSV.open("./data/comms.csv", "a") do |csv|
        csv << new_comm
      end
      # keep the comms array current
      commlist << new_comm
      true
    end

    def self.save_community_engagement(community_key, engagelist)
      new_engagement = [Time.now, community_key]
      CSV.open("./data/engagements.csv", "a") do |csv|
        csv << new_engagement
      end
      # keep the comms array current
      engagelist << new_engagement
      true
    end

end
