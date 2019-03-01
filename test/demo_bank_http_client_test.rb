# frozen_string_literal: true

require "test_helper"

class DemoBankHttpClientTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::DemoBankHttpClient::VERSION
  end

  def test_login_responds_with_error_when_email_is_missed
    assert_raises KeyError do
      DemoBankHttpClient::Client.new.login(password: "12345")
    end
  end

  def test_login_responds_with_error_when_password_is_missed
    assert_raises KeyError do
      DemoBankHttpClient::Client.new.login(email: "12345@em.com")
    end
  end

  def test_it_fails_to_login_with_wrong_credentials
    email = "demo@demo.com"
    password = "demo0"
    assert_equal false, DemoBankHttpClient::Client.new.login(email: email, password: password)
  end

  def test_it_logins_successfully_with_right_credentials
    email = "demo@demo.com"
    password = "demo"
    assert DemoBankHttpClient::Client.new.login(email: email, password: password)
  end

  def test_it_fails_getting_accounts_without_login_before
    client = DemoBankHttpClient::Client.new
    assert_raises DemoBankHttpClient::Error do
      client.accounts
    end
  end

  def test_it_fails_getting_accounts_with_failed_login_before
    email = "demo@demosd.com"
    password = "demoqwe"
    client = DemoBankHttpClient::Client.new
    assert_equal false, client.login(email: email, password: password)
    assert_raises DemoBankHttpClient::Error do
      client.accounts
    end
  end

  def test_getting_accounts_after_successful_login
    email = "demo@demo.com"
    password = "demo"
    expected_accounts = [
      { type: :current, balance: 10_000_855, currency: "BHD" },
      { type: :savings, balance: 534_599, currency: "USD" },
    ]
    client = DemoBankHttpClient::Client.new
    assert client.login(email: email, password: password)
    assert_equal expected_accounts, client.accounts
  end
end
