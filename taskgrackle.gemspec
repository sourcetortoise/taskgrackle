Gem::Specification.new do |s|
  s.name         = 'taskgrackle'
  s.version      = '1.0.1'
  s.date         = '2024-10-14'
  s.summary      = "An annoying grackle tells you what to do"
  s.description  = "Day manager for your console or dedicated Raspberry Pi-based household terminal."
  s.authors      = ["Mirth Turtle Media"]
  s.email        = 'christian@mirthturtle.com'
  s.files        = Dir["{lib}/**/*.rb", "bin/*", "*.md"]
  s.require_path = 'lib'
  s.homepage     = "https://mirthturtle.com/taskgrackle"
  s.executables  << 'taskgrackle'
end
