module GoogleDrive::CredentialStorage
  DEFAULE_FILE_STORE_PATH = '~/.google_drive-oauth2.json'

  class << self
    def store
      @store ||= Google::APIClient::FileStore.new(::File.expand_path(DEFAULE_FILE_STORE_PATH))
    end

    def store=(value)
      @store = value
    end
  end # of class methods

  def store
    GoogleDrive::CredentialStorage.store
  end

  def credential_stored?
    not store.load_credentials.nil?
  end

  def storage
    @storage ||= Google::APIClient::Storage.new(store)
  end
end
