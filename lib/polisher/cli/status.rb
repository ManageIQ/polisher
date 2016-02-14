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

    def waiting_msg(msg)
      conf[:wait_msg] = msg
    end

    def waiting(args={})
      waiting_msg(args[:msg]) if args.key?(:msg)
      color = args[:color] || :black

      @term_waiting = false
      @waiting_thread = Thread.new(conf) { |conf|
        until @term_waiting
          clear
          print conf[:wait_msg].send(color) if conf.key?(:wait_msg)
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

    def deprecated_warning!(target, reason='')
      puts "This #{target} has been deprecated! #{reason}\n".red.underline.bold
    end

    def utility_deprecated_warning!(reason='')
      deprecated_warning! "utility", reason
    end
  end # module CLI
end # module Polisher
