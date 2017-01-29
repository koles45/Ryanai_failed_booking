require 'selenium-webdriver'
require Dir.pwd + '/chromedriver_path.rb'
MAIN_PAGE = 'https://www.ryanair.com/ie/en/'.freeze
COUNTRIES = "//div[@ng-repeat='option in "\
  "$ctrl.firstOptions track by option.id']".freeze
ONE_WAY = 'lbl-flight-search-type-one-way'.freeze
MONTHS = %w(
  January February March April May June July
  August Spetember October November December
).freeze
CALENDAR_BASE = '#row-dates-pax > div:nth-child(1) > div > div.container-from'\
  ' > div > div.core-date-range.popup-start-date.opened > div > div > div.con'\
  'tent > popup-content > core-datepicker > div > div.datepicker-wrapper.r.sc'\
  'rollable > ul > li:nth-child('.freeze
CALENDAR_END = ') > ul.days'.freeze
NEXT_MONTH_BUTTON = "//button[@ng-click='slideToNextMonth()']".freeze
LETS_GO_BUTTON = "//button[@ng-click='searchFlights()']".freeze
LOGIN_BUTTON = "//button[@ui-sref='login']".freeze
TITLE_SELECT = "//select[@ng-model='passenger.name.title']".freeze
MOBILE_COUNTRY_SELECT = "//select[@name='phoneNumberCountry']".freeze
MOBILE_NR_FILL = "//input[@name='phoneNumber']".freeze
CARD_NR_FILL = "//input[@name='cardNumber']".freeze
EXP_ERROR_TITLE = 'Oh. There was a problem'.freeze
EXP_ERROR_MSG = 'As your payment was not authorised we could not'\
  ' complete your reservation. Please ensure that the information'\
  ' was correct or use a new payment to try again'.freeze
# adds colorization to String class, used in assertion method
class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  # indicates FAIL
  def red
    colorize(31)
  end

  # indicates PASS
  def green
    colorize(32)
  end

  # indicates WARN/ERROR
  def yellow
    colorize(33)
  end
end
##
# Author&Date: Grzegorz Borowik, 29.01.2017
# Description: This module extends SeleniumBrowser class for additional
#              methods providing User form data operations, it is used in
#              Ryanair booking test.
# Raises: This module can raise method specific exceptions.
# TO DO: -
module UserFormData
  def fill_name_surname_and_title(user)
    tries ||= 0
    puts "Inputing first name field: '#{name = user.first_name}'"
    get_elem_and_fill(:xpath, "//input[@placeholder='e.g. John']", name)
    puts "Inputing surname: '#{surname = user.surname}'"
    get_elem_and_fill(:xpath, "//input[@placeholder='e.g. Smith']", surname)
    puts "Selecting title: '#{title = user.title}'"
    select_item_from_list(:xpath, TITLE_SELECT, title)
  rescue Selenium::WebDriver::Error::InvalidElementStateError
    puts 'InvalidElementStateError occured, re-try'.yellow
    tries += 1
    sleep 1
    retry unless tries > 3
  end

  def fill_mobile_data(user)
    mobile_country = user.mobile_country
    puts "Selecting moble nr country: #{mobile_country}"
    select_item_from_list(:xpath, MOBILE_COUNTRY_SELECT, mobile_country)
    mobile_phone = user.mobile_phone
    puts "Inputing mobile nr: '#{mobile_phone}'"
    get_elem_and_fill(:xpath, MOBILE_NR_FILL, mobile_phone)
  end

  def fill_card_data(user)
    puts "Inputing card number: '#{number = user.pay_card.number}'"
    get_elem_and_fill(:xpath, CARD_NR_FILL, number)
    puts "Selecting card type: '#{card_type = user.pay_card.type}'"
    select_item_from_list(:xpath, "//select[@name='cardType']", card_type)
    puts "Selecting card expiry month: '#{expire_month = user.pay_card.expire_month}'"
    select_item_from_list(:xpath, "//select[@name='expiryMonth']", expire_month)
    puts "Selecting card expiry year: '#{expire_year = user.pay_card.expire_year}'"
    select_item_from_list(:xpath, "//select[@name='expiryYear']", expire_year)
    puts "Inputing card security code: '#{code = user.pay_card.security_code}'"
    get_elem_and_fill(:xpath, "//input[@maxlength='3']", code)
    puts "Inputing cardholders name: '#{name = user.pay_card.cardholder_name}'"
    get_elem_and_fill(:xpath, "//input[@placeholder='e.g. John Smith']", name)
  end

  def fill_location_data(user)
    puts "Inputing address 1: '#{adr1 = user.pay_card.adress_1}'"
    get_elem_and_fill(:id, 'sa.nameAddressLine1', adr1)
    puts "Inputing address 2: '#{adr2 = user.pay_card.adress_2}'"
    get_elem_and_fill(:id, 'sa.nameAddressLine2', adr2)
    # fills city
    get_elem_and_fill(:id, 'sa.nameCity', user.pay_card.city)
    puts "Inputing zip: '#{zip = user.pay_card.zip}'"
    get_elem_and_fill(:id, 'sa.namePostcode', zip)
    puts "Selecting country: '#{country = user.pay_card.country}'"
    select_item_from_list(:xpath, "//select[@id='sa.nameCountry']", country)
  end

  def fill_user_form(user)
    fill_name_surname_and_title(user)
    fill_mobile_data(user)
    fill_card_data(user)
    fill_location_data(user)
  end

  def accept_policy
    @browser.find_elements(:xpath, "//div[@class='terms']").first.click
  end

  def pay_now
    get_elem_and_click(:xpath, "//button[@ng-if='!pm.isMobile']")
  end

  def login(user)
    get_elem_and_click(:xpath, LOGIN_BUTTON)
    get_elem_and_fill(:xpath, "//input[@type='email']", user.email)
    get_elem_and_fill(:xpath, "//input[@name='password']", user.password)
    get_elem_and_click(:xpath, "//button[@type='submit']")
  end
end
##
# Author&Date: Grzegorz Borowik, 29.01.2017
# Description: This module extends SeleniumBrowser class for additional
#              methods providing booking date operations, it is used in
#              Ryanair booking test.
# Raises: This method should not raise any exception.
# TO DO: -
module BookingDate
  def find_avaiable_flights_in_month(month)
    unless MONTHS.include?(month)
      raise ArgumentError "Month you passed is: #{month} and should be"\
        " one of #{MONTHS}"
    end
    month_index = (MONTHS.index(month) + 1).to_s
    month_days = @browser.find_element(
      :css, CALENDAR_BASE + month_index + CALENDAR_END
    )
    blank_days = month_days.find_elements(:css, 'li.blank.unavailable')
    invalid_days = month_days.find_elements(:css, 'li.disabled.unavailable')
    not_avaiable_days = month_days.find_elements(:css, 'li.unavailable')
    avaiable_days = month_days.find_elements(:css, 'li')
    blank_days.each { |blank_day| avaiable_days.delete(blank_day) }
    invalid_days.each { |invalid_day| avaiable_days.delete(invalid_day) }
    not_avaiable_days.each { |not_avaiable_day| avaiable_days.delete(not_avaiable_day) }
    if avaiable_days.count.nonzero?
      puts "Found #{avaiable_days.count} avaiable days in #{month}!".green
      return avaiable_days
    else
      puts "No avaiable days in #{month} have been found!".yellow
      puts "Switching to next month: #{MONTHS[month_index.to_i]}"
      next_month
      return nil
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError
    puts "Month selected: #{month} not avaiable for booking.".yellow
  end

  def next_month
    get_elem_and_click(:xpath, NEXT_MONTH_BUTTON)
  end

  def select_country(user_country)
    countires = @browser.find_elements(:xpath, COUNTRIES)
    countires.each.find do |country|
      country.text == user_country
    end.click
  end

  def select_origin(country, city)
    get_elem_and_click(:xpath, "//input[@placeholder='Departure airport']")
    select_country(country)
    get_elem_and_click(:xpath, "//*[contains(text(), '#{city}')]")
  end

  def select_destination(country, city)
    select_country(country)
    get_elem_and_click(:xpath, "//*[contains(text(), '#{city}')]")
  end

  def choose_one_way
    get_elem_and_click(:id, ONE_WAY)
  end

  def lets_go
    get_elem_and_click(:xpath, LETS_GO_BUTTON)
  end
end
##
# Author&Date: Grzegorz Borowik, 29.01.2017
# Description: This class wraps Selenium Web Driver, it is used in
#              Ryanair booking test. Prowides web browsing
# Returns: SeleniumBrowser Object.
# Raises: This method should not raise any exception.
# TO DO: -
class SeleniumBrowser
  include BookingDate
  include UserFormData
  def initialize
    Selenium::WebDriver::Chrome.driver_path = CHROME_DRIVER_PATH
    @browser = Selenium::WebDriver.for :chrome
    @wait = Selenium::WebDriver::Wait.new(timeout: 25)
    @browser.manage.window.maximize
  end

  def go_to(url)
    @browser.navigate.to url
  end

  def quit
    @browser.close
  end

  def wait_for_booking_page_load
    get_element(:xpath, "//*[contains(text(), 'from')]")
  end

  def wait_for_recommended_page_load
    exp_text = 'Recommended for you'
    get_element(:xpath, "//*[contains(text(), '#{exp_text}')]")
  end

  def click_price
    try ||= 0
    get_elem_and_click(:xpath, "//*[contains(text(), 'from')]")
  rescue Selenium::WebDriver::Error::UnknownError => e
    puts 'click_price method could not be executed'\
      " coz of #{e}, tries again".yellow
    try += 1
    sleep 1
    retry unless try > 3
  end

  def scroll_to_elem(by, value)
    elem = get_element(by, value)
    elem.location_once_scrolled_into_view
    sleep 0.3
  end
  def countinue
    try ||= 0
    # scrolling to bottom of page before clicking
    # it's a backup if something is covering button
    scroll_to_elem(:xpath, "//core-icon[@icon-id='ryanair-logomark']")
    get_elem_and_click(:id, 'continue')
  rescue Selenium::WebDriver::Error::UnknownError => e
    puts "Error: '#{e.class}' occured, tries again #{try}".yellow
    try += 1
    sleep 1
    retry unless try > 5
  end

  def check_out
    get_elem_and_click(:xpath, "//*[contains(text(), 'Check out')]")
    begin
      try ||= 0
      seat_popup_ok
    rescue Selenium::WebDriver::Error::NoSuchElementError
      sleep 1
      try += 1
      get_elem_and_click(:xpath, "//*[contains(text(), 'Check out')]")
      retry unless try > 7
    rescue Selenium::WebDriver::Error::TimeOutError
      sleep 1
      try += 1
      get_elem_and_click(:xpath, "//*[contains(text(), 'Check out')]")
      retry unless try > 7
    end
  end

  def seat_popup_ok
    get_elem_and_click(:xpath, "//*[contains(text(), 'Ok, thanks')]")
  end

  def select_item_from_list(by, value, option_text)
    items = @browser.find_elements(by, value).first
    items.find_elements(tag_name: 'option').find do |option|
      option.text == option_text
    end.click
  end

  def cookie_popup_close
    get_elem_and_click(:xpath, "//core-icon[@icon-id='glyphs.close']")
  end

  def check_payment_error
    title_text = get_element(:xpath, "//div[@ng-if='$ctrl.textTitle']").text
    begin
      error_text = get_element(
        :xpath,
        "//div[@translate='common.components.payment_forms.error_explain_declined']"
      ).text
    rescue Selenium::WebDriver::Error::TimeOutError
      puts 'Timeout error occured when reading error message.'\
        ' Most likely some other error occured'.yellow
      error_text = 'NOT RECEIVED'
    end
    return title_text, error_text
  end

  def actual_url
    @browser.current_url
  end

  private

  def get_elem_and_fill(by, value, data)
    field = get_element(by, value)
    field.clear
    field.send_keys data
  end

  def get_elem_and_click(by, value)
    elem = get_element(by, value)
    elem.click
  end

  def get_element(by, value)
    @wait.until { @browser.find_element(by, value).displayed? }
    element = @browser.find_element(by, value) # ; @wait.until { element.displayed?}
    return @browser.find_element(by, value) if element
    raise "Element you have passed: #{value} with selector: #{by}"\
      " was not found on page in #{@wait.inspect} time"
  end
end
##
# Author&Date: Grzegorz Borowik, 28.01.2017
# Description: This class models user used in Ryanair booking test.
# Class should have accessors for all its parameters.
# All parameters need to be defined during initialization
# Parameters:
# [email]         -> string	Used for reading/writing user email
# [password]      -> string	Used for reading/writing user password
# [firstname]     -> string	Used for reading/writing user first name
# [surname]       -> string	Used for reading/writing user last name
# [title]         -> string  Used for reading/writing user title
# [mobile_country]-> string	Used for reading/writing user phone country
# [mobile_phone]  -> integer	Used for reading/writing user phone number
# [pay_card]      -> PaymentCard object	Used for reading/writing user credit card attributes
# [travel_from_country]-> string	Used for reading/writing user starting flight country
# [travel_from_city]   -> string	Used for reading/writing user starting flight city
# [travel_to_country]  -> string	Used for reading/writing user ending flight country
# [travel_to_city]   -> string	Used for reading/writing user ending flight city
#
# Returns: User object
# Raises: This class should not raise any exception.
# TO DO: -
class User
  attr_accessor :email, :password, :first_name, :surname, :title,
  :mobile_country, :mobile_phone, :pay_card, :travel_from_country,
  :travel_from_city, :travel_to_country, :travel_to_city
  def initialize(
      email, password, first_name, surname, title, mobile_country,
      mobile_phone, pay_card, travel_from_country, travel_from_city,
      travel_to_country, travel_to_city
  )
    @email = email
    @password = password
    @first_name = first_name
    @surname = surname
    @title = title
    @mobile_country = mobile_country
    @mobile_phone = mobile_phone
    @pay_card = pay_card
    @travel_from_country = travel_from_country
    @travel_from_city = travel_from_city
    @travel_to_country = travel_to_country
    @travel_to_city = travel_to_city
  end
end
##
# Author&Date: Grzegorz Borowik, 28.01.2017
# Description: This class models user Payment card used in Ryanair booking test.
# Class should have accessors for all its parameters.
# All parameters need to be defined during initialization
# Parameters:
# [number]    -> integer	Used for reading/writing cards number
# [type]      -> string	Used for reading/writing cards type e.g: Visa
# [expire_month]     -> string	Used for reading/writing cards expiration month
# [expire_year]     -> string	Used for reading/writing cards expiration year
# [security_code]-> integer  Used for reading/writing cards security code
# [cardholder_name]-> string Used for reading/writing cards owner
# [address_1]     -> string	Used for reading/writing cards owner address_1
# [address_2]     -> string	Used for reading/writing cards owner address_2
# [city]          -> string	Used for reading/writing cards city
# [zip]           -> string	Used for reading/writing cards zip code
# [country]       -> string	Used for reading/writing cards country
#
# Returns: PaymentCard object
# Raises: This class should not raise any exception.
# TO DO: -
class PaymentCard
  attr_accessor :number, :type, :expire_month, :expire_year, :security_code,
  :cardholder_name, :adress_1, :adress_2, :city, :zip, :country
  def initialize(
      number, type, expire_month, expire_year, security_code, cardholder_name,
      adress_1, adress_2, city, zip, country
  )
    @number = number
    @type = type
    @expire_month = expire_month
    @expire_year = expire_year
    @security_code = security_code
    @cardholder_name = cardholder_name
    @adress_1 = adress_1
    @adress_2 = adress_2
    @city = city
    @zip = zip
    @country = country
  end
end
# Used for determining if asserted values are pass or fail
def assert(msg, condition)
  if condition
    puts "PASS: #{msg}".green
  else
    puts "FAIL: #{msg}".red
  end
end
