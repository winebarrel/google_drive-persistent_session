require 'google/api_client/auth/storages/file_store'

class Google::APIClient::FileStore
  alias write_credentials_orig write_credentials

  def write_credentials(credentials_hash)
    write_credentials_orig(credentials_hash)
    FileUtils.chmod(0600, path)
  end
end
