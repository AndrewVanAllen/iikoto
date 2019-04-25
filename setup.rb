#!/usr/bin/ruby

# simple script to generate the initial stuffs
# in ruby for consistency

# Requires
require 'tty-prompt'
require 'sqlite3'
require 'bcrypt'
require 'fileutils'
require 'yaml'

# Define vars
config = YAML.load(File.read("config.yml")).freeze
boards = []
users = []
schema_uri = 'models/schemas/sqlite.sql' # uri on file system of schema to use as template
db_file = config[:connection][:database]
schema = '' << File.read(schema_uri)

# Use SecureRandom for the password salt
bcrypt = BCrypt::Engine
pass_salt = bcrypt.generate_salt


# Defite prompt
prompt = TTY::Prompt.new
args = ARGV

if !args[0]
  puts 'setup.rb: No arguments provided. '\
       'Usage: setup.rb [install|backup|uninstall|addboard|help]'
elsif args[0] == 'install'
  system "clear"

  if File.file?(db_file) # check for db_file
    prompt.say('You have already setup iikoto')
    exit 1
  elsif !File.file?(db_file)
    prompt.say('Starting initial setup...')
    users = prompt.collect do # ask for user info
      key(:admin) do
        key(:user).ask('Admin username (required): ', default: 'admin', required: true)
        key(:pass).mask('Admin password (required): ', required: true)
      end
    end
    boards = prompt.collect do # ask for board info
      key(:board) do
        key(:title).ask('Board title: ', required: true)
        key(:url).ask('Board URL: ', required: true)
      end
    end
  end

  prompt.say("Creating DB @ #{db_file}..")
  db = SQLite3::Database.new(db_file) # Register new db
  create_db = db.execute_batch('' << schema) # Load DB with schema from file
  prompt.say("Done.")

  prompt.say("Creating user...")
  create_user = db.execute("INSERT INTO users(username, password, salt) VALUES(\"#{users[:admin][:user].to_s.strip}\", \"#{bcrypt.hash_secret(users[:admin][:pass].to_s.strip, pass_salt)}\", \"#{pass_salt}\")")
  prompt.say("Done.")

  prompt.say("Creating board.")
  create_board = db.execute("INSERT INTO boards(route,name) VALUES(\"#{boards[:board][:url].to_s.strip}\", \"#{boards[:board][:title].strip}\")")
  prompt.say("Done. Now run your IB with `rackup` and navigate to wherever it says to in your browser.")

  exit 0

elsif args[0] == 'uninstall'
  system "clear"

  if !File.file?(db_file)
    prompt.say("You haven't run install yet")
    exit 1
  end
  if prompt.yes?("Are you sure you want to delete the current database at #{db_file}?")
    prompt.say("OK. Deleting #{db_file}...")
    File.delete(db_file)
    prompt.say("Done.")
    exit 0

  else
    exit 1
  end

elsif args[0] == 'addboard'
  system "clear"
  if !File.file?(db_file)
    prompt.say("You haven't installed iikoto yet.")
    exit 1
  end
  boards = prompt.collect do # ask for board info
    key(:board) do
      key(:title).ask('Board title: ', required: true)
      key(:url).ask('Board URL: ', required: true)
    end
  end
  prompt.say("Creating board.")
  db = SQLite3::Database.open(db_file)
  create_board = db.execute("INSERT INTO boards(route,name) VALUES(\"#{boards[:board][:url].to_s.strip}\", \"#{boards[:board][:title].strip}\")")
  prompt.say("Done.")
  exit 0
elsif args[0] == 'backup'
  system "clear"
  if !File.file?(db_file)
    prompt.say("No file to backup!")
    exit 1
  end
  backup_uri = prompt.ask("Where do you want to backup to? (relative paths allowed)", default: "./iikoto-#{Time.now.strftime('%d-%m-%y')}-backup.db")
  prompt.say("Backing up...")
  FileUtils.cp(db_file, backup_uri)
  prompt.say("Done.")
  exit 0
elsif args[0] == 'help'
  system "clear"
  puts 'Usage: setup.rb [install|uninstall|addboard|backup|help]'
  puts '  install     enter board setup'
  puts '  uninstall   enter board uninstallation'
  puts '  backup      backup board db'
  puts '  addboard    add a new board'
  puts '  help        show this help'

  exit 0
else
  system "clear"
  puts "setub.rb: Error: Argument #{arg[0]} doesn't exist. See: `./setup.rb help` for usage."
  exit 1
end
