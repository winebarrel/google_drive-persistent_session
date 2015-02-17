require 'fileutils'
require 'forwardable'
require 'google/api_client'
require 'google/api_client/auth/file_storage'
require 'google_drive'
require 'highline'

module GoogleDrive
  class PersistentSession
    extend Forwardable

    def_delegator :@highline, :ask

    THREAD_KEY = "#{self.to_s}::THREAD_KEY"
    DEFAULE_CREDENTIAL_STORE_FILE = '~/.google_drive-oauth2.json'
    REFRESH_BUFFER = 300

    class << self
      def credential_store_file
        @credential_store_file ||= ::File.expand_path(DEFAULE_CREDENTIAL_STORE_FILE)
      end

      def credential_store_file=(value)
        @credential_store_file = value
      end

      def login
        self.new
      end
    end

    def initialize
      @highline = HighLine.new
      ensure_login
    end

    private

    def ensure_login
      unless credential_stored?
        create_credential_store_file
      end

      credential = file_storage.load_credentials

      if !credential.access_token
        fetch_access_token(credential)
      elsif expired?(credential)
        refresh(credential)
      end

      unless session
        login_with_oauth(credential.access_token)
      end
    end

    def credential_stored?
      ::File.exist?(self.class.credential_store_file)
    end

    def expired?(credential)
      credential.issued_at + credential.expires_in - REFRESH_BUFFER <= Time.new
    end

    def create_credential_store_file
      client_id = ask('Enter CLIENT ID: ')
      client_secret = ask('Enter CLIENT SECRET: ') {|q| q.echo = false }
      puts # line break

      credential = Signet::OAuth2::Client.new(
        :client_id => client_id,
        :client_secret => client_secret,
        :refresh_token => ''
      )

      file_storage.write_credentials(credential)
      FileUtils.chmod(0600, credential_store_file)
    end

    def fetch_access_token(credential)
      credential.scope = %w(
        https://www.googleapis.com/auth/drive
        https://spreadsheets.google.com/feeds/
      ).join(' ')

      credential.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
      credential.grant_type = 'authorization_code'

      message =  "1. Open this page:\n%s\n\n" % credential.authorization_uri
      message << "2. Enter the authorization code shown in the page: "
      credential.code = ask(message)

      credential.fetch_access_token!
      file_storage.write_credentials(credential)
      login_with_oauth(credential.access_token)
    end

    def refresh(credential)
      credential.refresh!
      file_storage.write_credentials(credential)
      login_with_oauth(credential.access_token)
    end

    def session
      Thread.current[THREAD_KEY]
    end

    def login_with_oauth(access_token)
      Thread.current[THREAD_KEY] = GoogleDrive.login_with_oauth(access_token)
    end

    def file_storage
      @file_storage ||= Google::APIClient::FileStorage.new(credential_store_file)
    end

    def credential_store_file
      self.class.credential_store_file
    end

    def method_missing(method_name, *args , &block)
      ensure_login
      session.send(method_name, *args, &block)
    end
  end
end
