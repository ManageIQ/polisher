#!/usr/bin/ruby
# Polisher CLI Target Options
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def set_format(conf)
      @format = conf[:format]
    end
    
    def format_dep(dep)
      if @format.nil?
        dep.to_s.blue.bold
      elsif @format == 'xml'
        "<#{dep}>"
      elsif @format == 'json'
        "'#{dep}':{"
      end
    end
    
    def format_end_dep(dep)
      if @format.nil?
        "\n"
      elsif @format == 'xml'
        "\n</#{dep}>"
      elsif @format == 'json'
        "\n}"
      end
    end
    
    def format_tgt(tgt)
      if @format.nil?
        " #{tgt.to_s.red.bold}"
      elsif @format == 'xml'
        "<#{tgt}/>"
      elsif @format == 'json'
        "'#{tgt}':null,"
      end
    end
    
    def format_unknown_tgt(tgt)
      if @format.nil?
        "#{tgt.to_s.red.bold}: " + "unknown".yellow
      else
        format_tgt("#{tgt} (unknown)")
      end
    end
    
    def format_tgt_with_versions(tgt, versions)
      if @format.nil?
        " #{tgt.to_s.green.bold}: #{versions.join(', ').yellow}"
      elsif @format == 'xml'
        "<#{tgt}>#{versions.join(', ')}</#{tgt}>"
      elsif @format == 'json'
        "'#{tgt}':['#{versions.join('\', \'')}'],"
      end
    end

    def pretty_dep(tgt, dep, versions)
      pretty = ''

      # XXX little bit hacky but works for now
      @last_dep ||= nil
      if @last_dep != dep
        pretty += format_end_dep(@last_dep) unless @last_dep.nil?
        pretty += format_dep(dep)
        @last_dep = dep
      end

      if versions.blank? || (versions.size == 1 && versions.first.blank?)
        pretty += format_tgt(tgt)

      elsif versions.size == 1 && versions.first == :unknown
        pretty += format_unknown_tgt(tgt)

      else
        pretty += format_tgt_with_versions(tgt, versions)
      end

      pretty
    end

    def last_dep # XXX
      format_end_dep(@last_dep) unless @last_dep.nil?
    end
  end # module CLI
end # module Polisher
