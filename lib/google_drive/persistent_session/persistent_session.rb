require 'securerandom'
require 'uri'
require 'webrick'

class GoogleDrive::PersistentSession
  extend Forwardable
  include GoogleDrive::CredentialStorage

  def_delegator :@highline, :ask

  THREAD_KEY = "#{self.to_s}::THREAD_KEY"

  def self.login
    self.new
  end

  def initialize
    @highline = HighLine.new
    ensure_login
  end

  private

  def ensure_login
    store_credential unless credential_stored?
    credential = storage.authorize

    if credential.expired?
      refresh(credential)
    end

    unless session
      login_with_oauth(credential.access_token)
    end
  end

  def store_credential
    client_id = ask('Enter CLIENT ID: ')
    client_secret = ask('Enter CLIENT SECRET: ') {|q| q.echo = false }
    puts # line break

    # Use loopback IP address redirect option
    # https://developers.google.com/identity/protocols/oauth2/native-app#redirect-uri_loopback
    server = WEBrick::HTTPServer.new(Port: 0, AccessLog: [])
    queue = Thread::SizedQueue.new(1)
    health_token = SecureRandom.uuid
    server.mount_proc('/') do |req, resp|
      resp.content_type = 'text/plain'
      if req.request_method != 'GET'
        resp.status = 405
        res.body = 'Method Not Allowed'
        next
      end

      case req.path
      when '/'
        # redirect
        params = URI.decode_www_form(req.query_string).to_h
        if params.key?('code')
          code = params.fetch('code')
          resp.status = 200
          resp.body = 'Successfully authorized. Back to console'
          queue.push(code)
        else
          resp.status = 400
          resp.body = 'Failed to authorize: code is missing'
          queue.push(nil)
        end
      when '/health'
        resp.status = 200
        resp.body = health_token
      else
        resp.status = 404
        resp.body = 'not found'
      end
    end
    server_thread = Thread.start { server.start }
    credential =  Google::Auth::UserRefreshCredentials.new(
      :client_id => client_id,
      :client_secret => client_secret,
      :scope => [
        'https://www.googleapis.com/auth/drive',
        'https://spreadsheets.google.com/feeds/'
      ],
      :redirect_uri => "http://127.0.0.1:#{server.config[:Port]}",
      :grant_type => 'authorization_code'
    )

    server_launched = false
    60.times do |i|
      begin
        resp = Net::HTTP.get_response('127.0.0.1', '/health', server.config[:Port])
        resp.value
        if resp.body == health_token
          server_launched = true
          break
        else
          $stderr.puts "  Server returned unknown response: #{resp.body}"
          sleep 1
        end
      rescue => e
        $stderr.puts "  Waiting server launch: #{e.class}: #{e.message}"
        sleep 1
      end
    end
    unless server_launched
      server.shutdown
      server_thread.join
      raise 'Failed to start HTTP server'
    end
    fetch_access_token(credential, queue, server, server_thread)
    storage.write_credentials(credential)
  end

  def fetch_access_token(credential, queue, server, server_thread)
    puts "Open this page in web browser: #{credential.authorization_uri}"
    code = queue.pop
    server.shutdown
    server_thread.join
    unless code
      raise 'authorization failed'
    end
    credential.code = code

    credential.fetch_access_token!
    storage.write_credentials(credential)
    login_with_oauth(credential.access_token)
  end

  def refresh(credential)
    credential.refresh!
    storage.write_credentials(credential)
    login_with_oauth(credential.access_token)
  end

  def session
    Thread.current[THREAD_KEY]
  end

  def login_with_oauth(access_token)
    Thread.current[THREAD_KEY] = GoogleDrive.login_with_oauth(access_token)
  end

  def method_missing(method_name, *args , &block)
    ensure_login
    session.send(method_name, *args, &block)
  end
end
