require 'json'

module Lita
  module Handlers
    class StatusMe < Handler
      GITHUB_STATUS_API_URI = URI.parse('https://status.github.com/api/status.json').freeze

      route(/\Astatus loop(?: \w+)?\z/i, :loop, command: true, help: {
        'status loop' => 'checks the GitHub status API every minute',
        'status loop stop' => 'stops the loop checking the GitHub status API'
      })

      route(/\Astatus(?: me)?\z/i, :reply_with_github_status, command: true, help: {
        'status me' => 'checks the GitHub status API'
      })

      def reply_with_github_status(req, only_errors = false)
        status = check_github_status
        req.reply "status: #{status}" if should_return_status?(status, only_errors)
      end

      def loop(req)
        every(60) do |timer|
          timer.stop if stop_request?(req)
          reply_with_github_status(req, true)
        end
      end

      private
      def check_github_status
        res = Net::HTTP.get_response(GITHUB_STATUS_API_URI)
        return 'Error reaching GitHub API' unless res.code == '200'
        JSON.parse(res.body, symbolize_names: true)[:status]
      end

      def stop_request?(req)
        req.match_data[1] && req.match_data[1].strip == 'stop'
      end

      def should_return_status?(status, only_errors)
        (only_errors == true && status != 'good') ||
          only_errors == false
      end

      Lita.register_handler(self)
    end
  end
end
