# frozen_string_literal: true

require "demo_bank_http_client/version"
require "nokogiri"
require "faraday"
require "monetize"

module DemoBankHttpClient
  class Error < StandardError; end

  class Client
    BANK_URL = "https://verify-demo-bank.herokuapp.com/"
    LOGGED_IN_HTML_BODY = "<html><body>You are being <a href=\"https://verify-demo-bank.herokuapp.com/\">redirected</a>.</body></html>"

    def initialize
      @connection = Faraday.new(url: BANK_URL)
    end

    def login(credentials)
      email = credentials.fetch(:email)
      password = credentials.fetch(:password)

      response_with_login_form = @connection.get("/login")

      doc = Nokogiri::HTML(response_with_login_form.body)
      authenticity_token =
        doc.xpath("/html/body/form/input[@name='authenticity_token'][@type='hidden']")
           .first
           .attribute("value")
           .value

      @connection.headers["Cookie"] = response_with_login_form.headers["set-cookie"]

      response_on_submitted_form = @connection.post(
        "/login",
        utf8: "✓",
        authenticity_token: authenticity_token,
        email: email,
        password: password,
      )

      if response_on_submitted_form.status == 302 &&
          response_on_submitted_form.body == LOGGED_IN_HTML_BODY
        @connection.headers["Cookie"] = response_on_submitted_form.headers["set-cookie"]
        true
      else
        false
      end
    end

    def accounts
      response = @connection.get("/accounts")
      if response.status == 200
        doc = Nokogiri::HTML(response.body)
        doc
          .xpath("/html/body/div[@class='container-fluid']/table[last()]/tbody/tr")
          .map do |row|
            m = Monetize.parse(row.xpath('td').text)
            {
              type: row.xpath('th').text.downcase.to_sym,
              balance: m.cents,
              currency: m.currency.to_s
            }
        end
      elsif response.status == 302 && response.body.match("/login")
        raise Error, "Try to use #login before getting accounts list"
      else
        raise Error, "Something goes wrong..."
      end
    end
  end
end
