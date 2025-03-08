# frozen_string_literal: true

require 'socket'

module VolvoAPI
  # Class to spin up a temporary server to handle responses from the Volvo developer API
  class Server
    def initialize
      @server = TCPServer.new(ENV['PORT'])
    end

    def start_and_wait_for_code
      while (session = @server.accept)
        code = handle_session(session)

        if code
          @server.close
          return code
        end
      end
    end

    private

    def handle_session(session)
      request = session.gets

      code = read_code_from_query(request)
      return session.close if code.nil?

      send_basic_response(session)

      session.close

      code
    end

    def send_basic_response(session)
      session.print "HTTP/1.1 200\r\n"
      session.print "Content-Type: text/html\r\n"
      session.print "\r\n"
      session.print "It should've worked head back to your terminal"
    end

    def read_code_from_query(request)
      full_path = request.split(' ')[1]
      query = full_path.split('?')[1]

      query.split('=')[1]
    end
  end
end
