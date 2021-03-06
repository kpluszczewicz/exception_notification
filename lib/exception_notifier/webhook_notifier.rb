require 'action_dispatch'

module ExceptionNotifier
  class WebhookNotifier

    def initialize(options)
      @default_options = options
    end

    def call(exception, options={})
      env = options[:env]

      options = options.reverse_merge(@default_options)
      url = options.delete(:url)
      http_method = options.delete(:http_method) || :post

      options[:body] ||= {}
      options[:body][:server] = Socket.gethostname
      options[:body][:process] = $$
      options[:body][:rails_root] = Rails.root if defined?(Rails)
      options[:body][:exception] = {:error_class => exception.class.to_s,
                                    :message => exception.message.inspect,
                                    :backtrace => exception.backtrace}
      options[:body][:data] = (env['exception_notifier.exception_data'] || {}).merge(options[:data] || {})

      unless env.nil?
        request = ActionDispatch::Request.new(env)

        request_items = {:cookies => request.cookies.inspect,
                         :url => request.original_url,
                         :ip_address => request.remote_ip,
                         :parameters => request.filtered_parameters,
                         :session => request.session,
                         :environment => request.filtered_env,
                         :timestamp => Time.current }

        options[:body][:request] = (request_items || {})
      end

      HTTParty.send(http_method, url, options)
    end
  end
end
