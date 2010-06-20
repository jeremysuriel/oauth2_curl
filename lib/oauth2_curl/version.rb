module Oauth2Curl
  module VERSION
    MAJOR  = '0'
    MINOR  = '6'
    TINY   = '1'
    BETA   = nil # Time.now.to_i.to_s
  end

  Version = [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY, VERSION::BETA].compact * '.'
end
