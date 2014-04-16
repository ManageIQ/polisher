# Polisher Kerberos Operations
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'awesome_spawn'

module Polisher
  class Kerberos
    KINIT_CMD = '/usr/bin/kinit'

    # need to update the krb5-auth gem to include 'recent' changes:
    # https://github.com/timfel/krb5-auth
    # require 'krb5_auth'
    # def self.auth(user, pass)
    #  krb = Krb5Auth::Krb5.new
    #  krb5.get_init_creds_password('user', 'pass')
    #  krb.cache
    #  krb.close
    # end

    def self.auth(user, pass)
      AwesomeSpawn.run("#{KINIT_CMD} #{user}", :in_data => pass)
    end
  end # class Kerberos
end # module Polisher
