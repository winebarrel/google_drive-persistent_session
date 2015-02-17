# GoogleDrive::PersistentSession

Persist credential for [google-drive-ruby](https://github.com/gimite/google-drive-ruby).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'google_drive-persistent_session'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install google_drive-persistent_session

## Usage

```ruby
require 'google_drive/persistent_session'

#GoogleDrive::PersistentSession.credential_store_file = '~/.google_drive-oauth2.json'

session = GoogleDrive::PersistentSession.login

session.files.each do |file|
  puts file.title
end
```
