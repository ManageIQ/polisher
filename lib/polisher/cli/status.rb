#!/usr/bin/ruby
# Polisher CLI Status Utils
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def clear
      puts `clear`
    end

    def num_elipses
      conf[:num_elipses] ||= 5
    end

    def elipses_delay
      conf[:elipses_delay] ||= 1
    end

    def waiting(args={})
      msg   = args[:msg]
      color = args[:color] || :black

      @term_waiting = false
      @waiting_thread = Thread.new(msg) { |msg|
        until @term_waiting
          clear
          print msg.send(color) unless msg.nil?
          0.upto(num_elipses) {
            print '.'.send(color)
            sleep elipses_delay
          }
          puts
        end
      }
    end

    def end_waiting
      return unless @waiting_thread
      @term_waiting = true
      @waiting_thread.join
    end
  end # module CLI
end # module Polisher
