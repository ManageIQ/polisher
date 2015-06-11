# Polisher CLI Target Options
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'colored'

module Polisher
  module CLI
    def set_format(conf)
      @format = conf[:format]
    end

    def format_title(title)
      if @format.nil?
        title.to_s.blue.bold + ' '
      elsif @format == 'xml'
        "<#{title}>"
      elsif @format == 'json'
        "'#{title}':{"
      end
    end
    
    def format_end(closer)
      if @format.nil?
        "\n"
      elsif @format == 'xml'
        "\n</#{closer}>"
      elsif @format == 'json'
        "\n}"
      end
    end

    def format_missing_dep(dep)
      if @format.nil?
        "\n #{dep.to_s.red.bold}"
      elsif @format == 'xml'
        "<#{dep.name}>#{dep.requirement}</#{dep.name}>"
      elsif @format == 'json'
        "'#{dep.name}':'#{dep.requirement}'"
      end
    end

    def format_dep(dep, resolved_dep)
      if @format.nil?
        "\n #{dep.to_s.green.bold} (#{resolved_dep.version})"
      elsif @format == 'xml'
        "<#{dep.name}>#{dep.requirement}/#{resolved_dep.version}</#{dep.name}>"
      elsif @format == 'json'
        "'#{dep.name}':'#{dep.requirement}/#{resolved_dep.version}'"
      end
    end
    
    def pretty_dep(gem, dep, resolved_dep)
      pretty = ''

      # XXX little bit hacky but works for now
      @last_gem ||= nil
      if @last_gem != gem
        pretty += format_end(@last_dep.name) unless @last_gem.nil?
        pretty += format_title(gem.is_a?(Gemfile) ? "Gemfile" : "#{gem.name} #{gem.version}")
        @last_gem = gem
      end

      pretty += resolved_dep.nil? ? format_missing_dep(dep) : format_dep(dep, resolved_dep)
      @last_dep = dep
      pretty
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

    def pretty_tgt(dep, tgt, versions)
      pretty = ''

      @last_dep ||= nil
      if @last_dep != dep
        pretty += format_end(@last_dep) unless @last_dep.nil?
        pretty += format_title(dep)
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
      format_end(@last_dep) unless @last_dep.nil?
    end

    def last_gem # XXX
      format_end(@last_gem) unless @last_gem.nil?
    end
  end # module CLI
end # module Polisher
