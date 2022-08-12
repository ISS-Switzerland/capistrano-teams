require 'capistrano'
require 'net/http'
require 'uri'
require 'json'
require 'capistrano/teams/message/types'

module Capistrano
  module Teams
    # Teams Webhook class
    class WebHook
      def notify(
        status = fetch(:teams_default_status),
        theme_color = fetch(:teams_default_color),
        facts = []
      )
        content = Message::Builder.of_type(
          fetch(:teams_message_type),
          {
            status: status
          },
          theme_color,
          facts
        ).content
        send_message_to_webhook(content)
      end

      # Post to Teams.
      def send_message_to_webhook(body)
        uri = URI.parse(fetch(:teams_webhook_url).to_s)
        request = Net::HTTP::Post.new(uri.path)
        request.content_type = 'application/json'
        request.body = body

        opts = { use_ssl: uri.scheme == 'https' } \
               .merge(fetch(:teams_http_options))

        Net::HTTP.start(uri.host, uri.port, opts) do |http|
          http.request(request)
        end
      rescue => e
        fetch(:ignore_network_issue) ? print_err_message : raise(e)
      end

      private

      def print_err_message
        p 'Can\'t send notification to teams, continue without notification.'
      end
    end
  end
end
