require 'io/console'
require 'ostruct'
require 'curses'


class Tutor
  attr_accessor :lines,
                :position,
                :initial_cursor,
                :cursor,
                :visible_line_count,
                :mismatch,
                :window

  def initialize(file:, line: 0, char: 0, visible_line_count: 14)
    @lines = File.readlines(file).map(&:rstrip)
    @position = OpenStruct.new(line: line, char: char)
    @initial_cursor = @cursor = OpenStruct.new(row: 2, column: 0)
    @visible_line_count = visible_line_count
    @mismatch = false
  end

  def line
    lines[position.line]
  end

  def char
    line[position.char]
  end

  def set_initial_cursor
    window.setpos(initial_cursor.row, initial_cursor.column)
  end

  def set_cursor
    window.setpos((position.line < 5 ? position.line : 4) + cursor.row, position.char + cursor.column)
  end

  def advance_line
    @position.line += 1

    if line.length == 0
      advance_line
    end

    @position.char = 0

    while char == " "
      @position.char += 1
    end
  end

  def advance_position
    if char_is_line_end?
      advance_line
    else
      @position.char += 1
    end
  end

  def start
    Curses.init_screen

    @window ||= Curses::Window.new(20, Curses.cols, 0, 0)

    loop do
      draw

      ch = window.getch

      if ch == char
        self.mismatch = false
        advance_position
      else
        self.mismatch = true
      end
    end
  ensure
    Curses.close_screen
  end

  def draw
    window.refresh

    set_initial_cursor

    visible_lines.each do |visible_line|
      if mismatch && visible_line == line
        window.addstr(visible_line + " ERROR!" + "\n")
      else
        window.addstr(visible_line + "\n")
      end
    end

    set_cursor
  end

  def start_line
    position.line < 5 ? 0 : (position.line - 4)
  end

  def visible_lines
    lines[start_line..end_line]
  end

  def line_end
    line.length - 1
  end

  def char_is_line_end?
    line_end == position.char
  end

  def end_line
    (position.line + visible_line_count) >= last_line ?
      last_line :
      position.line + visible_line_count
  end

  def last_line
    lines.length - 1
  end
end

repo = 'https://github.com/elixir-lang/elixir.git'
dir_name = 'elixir'
file_extension = '*.ex'

if Dir.exists?(dir_name)
  system "cd #{dir_name} && git pull"
else
  system "git clone #{repo} #{dir_name}"
end

files = `cd #{dir_name} && git ls-files #{file_extension}`

files = files.split("\n")

loop do
  file = files.sample

  system 'clear'

  puts 'Practice with this file? (y/n/q)'
  puts file
  puts

  puts `cd #{dir_name} && head -20 #{file.strip}`

  case STDIN.getch
  when 'y'
    @file = file
    break
  when 'q'
    exit
  end
end

tutor = Tutor.new(file: "#{dir_name}/#{@file}")

tutor.start
