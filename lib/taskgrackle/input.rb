# TASKGRACKLE - Input module
require 'io/console'

class Input
  def self.checkin; ['1', ' '] end
  def self.mood_and_habit_checkup; ['2', 'm'] end
  def self.exercise_key; '3' end
  def self.dayplan_key; '4' end
  def self.work_hour; ['5', 'w'] end
  def self.grocery_prep; '6' end
  def self.friends_key; '7' end
  def self.communities_key; '8' end
  def self.relaxation_key; '9' end
  def self.history; '0' end
  def self.settings; ['s', '-'] end
  def self.debug_menu; '+' end
  def self.settings_space; [' ', '-'] end
  def self.exercise_choices; ['1', '2', '3', '4', '5', '6'] end
  def self.integers; ['1', '2', '3', '4', '5', '6', '7', '8', '9'] end
  def self.break; ['q', 'x'] end
  def self.space; ' ' end
  def self.nofilter_key; '-' end
  def self.backdate; '=' end
  def self.money_key; '7' end
  def self.vice_key; 't' end
  def self.annoying_key; 'a' end
  def self.speed_options; ['v', 's', 'n', 'c'] end

  # Get single character input
  def self.get
    begin
      system("stty raw -echo")
      str = STDIN.getch
    ensure
      system("stty -raw echo")
    end
    str
  end

  def self.space_to_continue
    input = get
    while !space.include?(input) # exit out with space bar
      input = get
    end
  end

  # grab whole line w/o trailing newline
  def self.read_line
    line = gets.chomp
  end

end
