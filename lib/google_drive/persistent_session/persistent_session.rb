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

    if !credential.access_token
      fetch_access_token(credential)
    elsif credential.expired?
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

    credential = Signet::OAuth2::Client.new(
      :client_id => client_id,
      :client_secret => client_secret,
      :refresh_token => ''
    )

    storage.write_credentials(credential)
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
