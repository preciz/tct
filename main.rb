require 'io/console'
require 'ostruct'
require 'curses'


class Tutor
  attr_accessor :lines,
                :position,
                :initial_cursor,
                :cursor,
                :visible_line_count,
                :window

  def initialize(file:, line: 0, char: 0, visible_line_count: 10)
    @lines = File.readlines(file).map(&:rstrip)
    @position = OpenStruct.new(line: line, char: char)
    @initial_cursor = @cursor = OpenStruct.new(row: 2, column: 0)
    @visible_line_count = visible_line_count
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
    window.setpos((position.line < 3 ? position.line : 2) + cursor.row, position.char + cursor.column)
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
        advance_position
      end
    end
  ensure
    Curses.close_screen
  end

  def draw
    set_initial_cursor

    visible_lines.each do |line|
      window.addstr(line + "\n")
    end

    set_cursor
  end

  def start_line
    position.line < 3 ? 0 : (position.line - 2)
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

tutor = Tutor.new(file: "test.ex")

system 'clear'

tutor.start
