#
# Implementation of the Arc Challenge using Wee.
#
# By Michael Neumann (mneumann@ntecs.de)
#
# http://onestepback.org/index.cgi/Tech/Ruby/ArcChallenge.red
#

$LOAD_PATH.unshift "../lib"
require 'rubygems'
require 'wee'
require "io"

class Conversation < Wee::Task
  def run
    io = Wee::IO.new(self)
    text = io.ask
    io.pause("click here")
    io.tell("You said: #{text}")
  end
end

Wee.runcc(Conversation) if __FILE__ == $0
