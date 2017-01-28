require 'selenium-webdriver'
FROM_FIELD = 'label-airport-selector-from'.freeze
TO_FIELD = 'label-airport-selector-to'.freeze
MAIN_PAGE = 'https://www.ryanair.com/ie/en/'
POLAND_XPATH = '//*[@id="search-container"]/div[1]/div/form/div[1]/div[2]/div'\
  '/div[1]/div[3]/div/div/div[2]/popup-content/core-linked-list/div[1]/div/div[26]'
GRECE_XPATH = '//*[@id="search-container"]/div[1]/div/form/div[1]/div[2]/div/'\
  'div[2]/div[3]/div/div/div[2]/popup-content/core-linked-list/div[1]/div/div[13]'
ONE_WAY = 'lbl-flight-search-type-one-way'
MONTHS = %w(
 January February March April May June July
 August Spetember October November December
)
CALENDAR_BASE = '#row-dates-pax > div:nth-child(1) > div > div.container-from'\
  ' > div > div.core-date-range.popup-start-date.opened > div > div > div.con'\
  'tent > popup-content > core-datepicker > div > div.datepicker-wrapper.r.sc'\
  'rollable > ul > li:nth-child('
CALENDAR_END = ') > ul.days'
NEXT_MONTH_BUTTON = '//*[@id="row-dates-pax"]/div[1]/div/div[1]/div/div[3]/di'\
  'v/div/div[2]/popup-content/core-datepicker/div/div[2]/button[2]'
LETS_GO_BUTTON = '//*[@id="search-container"]/div[1]/div/form/div[3]/button[2]'
TEST_USER_LOGIN = 'l536270@mvrht.com'
TEST_USER_PASS = '12345678aA'
LOGIN_BUTTON = '/html/body/div[2]/main/section/total-header/div/div/button[2]'
TITLE_XPATH = '//*[@id="checkout"]/div/form/div[1]/div[1]/div/div[2]/ng-form/'\
  'passenger-input-group/div/ng-form/div[1]/div[1]/div'
MOBILE_COUNTRY_XPATH = '//*[@id="checkout"]/div/form/div[1]/div[2]/div[2]/contact-'\
  'details-form/div/div[1]/div[3]/div/div[1]/div'
class SeleniumBrowser
  def initialize
    chromedriver_path = File.join('C:\Users\Grzesiek\Documents\NetBeansProjects\Ryanair_booking_page\lib\Ryanai_failed_booking\driver', 'chromedriver.exe')
    #chromedriver_path = File.path('/driver/chromedriver.exe')
    Selenium::WebDriver::Chrome.driver_path = chromedriver_path
    @browser = Selenium::WebDriver.for :chrome
    @wait = Selenium::WebDriver::Wait.new(:timeout => 15)
    @browser.manage().window().maximize();
  end
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
    blank_days.each{|blank_day| avaiable_days.delete(blank_day)}
    invalid_days.each{|invalid_day| avaiable_days.delete(invalid_day) }
    not_avaiable_days.each{|not_avaiable_day| avaiable_days.delete(not_avaiable_day) }
    if avaiable_days.count.nonzero?
      puts "Found #{avaiable_days.count} avaiable days in #{month}!"
      return avaiable_days
    else
      puts "No avaiable days in #{month} have been found!"
      puts "Switching to next month: #{MONTHS[month_index.to_i]}"
      next_month
      return nil
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError
    puts "Month selected: #{month} not avaiable for booking."
  rescue Exception => e
    puts e
    puts e.class
  end
  def next_month
    get_elem_and_click(:xpath, NEXT_MONTH_BUTTON)
  end
  def go_to(url)
    @browser.navigate.to url
  end
  def quit
    @browser.close
  end
  def select_origin(country, city)
    get_elem_and_click(:id, FROM_FIELD)
    get_elem_and_click(:xpath, country)
    get_elem_and_click(:xpath, "//*[contains(text(), '#{city}')]")
  end
  def select_destination(country, city)
    get_elem_and_click(:xpath, country)
    get_elem_and_click(:xpath, "//*[contains(text(), '#{city}')]")
  end
  def choose_one_way
    get_elem_and_click(:id, ONE_WAY)
  end
  def lets_go
    get_elem_and_click(:xpath, LETS_GO_BUTTON)
  end
  def wait_for_booking_page_load
    get_element(:xpath, "//*[contains(text(), 'from')]")
  end
  
  def wait_for_recommended_page_load
    exp_text = 'Recommended for you'
    get_element(:xpath, "//*[contains(text(), '#{exp_text}')]")
  end
  def click_price
    get_elem_and_click(:xpath, "//*[contains(text(), 'from')]")
  end
  def countinue
    get_elem_and_click(:id, 'continue')
  end
  def check_out
    sleep 1
    get_elem_and_click(:xpath, "//*[contains(text(), 'Check out')]")
  end
  def seat_popup_ok
    get_elem_and_click(:xpath, "//*[contains(text(), 'Ok, thanks')]")
  end
  def login
    get_elem_and_click(:xpath, LOGIN_BUTTON)
    email_field = get_element(:xpath, "//input[@type='email']")
    email_field.clear
    email_field.send_keys TEST_USER_LOGIN
    pass_field = get_element(:xpath, "//input[@name='password']")
    pass_field.clear
    pass_field.send_keys TEST_USER_PASS
    get_elem_and_click(:xpath, "//button[@type='submit']")
  end
  def fill_user_form(user)
    # filling first name field
    get_elem_and_fill(:xpath, "//input[@placeholder='e.g. John']", user.first_name)
    # filling surname
    get_elem_and_fill(:xpath, "//input[@placeholder='e.g. Smith']", user.surname)
    # selecting title
    titles_div = @browser.find_elements(:xpath, TITLE_XPATH)
    titles = titles_div[0]
    titles.find_elements( :tag_name => "option" ).find do |option|
      option.text == user.title
    end.click
    # selecting moble nr country
    country_div = @browser.find_elements(:xpath, MOBILE_COUNTRY_XPATH)
    countries = country_div[0]
    countries.find_elements( :tag_name => "option" ).find do |option|
      option.text == user.mobile_country
    end.click
    # filling mobile nr
    get_elem_and_fill(:xpath, "//input[@maxlength='13']", user.mobile_phone)
    # filling card number
    get_elem_and_fill(
      :xpath, "//input[@placeholder='Enter card number']", user.pay_card.number
    )
    # selecting card type
    card_types = @browser.find_elements(:xpath, "//select[@name='cardType']")
    card_types = card_types[0]
    card_types.find_elements( :tag_name => "option" ).find do |option|
      option.text == user.pay_card.type
    end.click
    # selecting expiry month
    months = @browser.find_elements(:xpath, "//select[@name='expiryMonth']").first
    months.find_elements( :tag_name => "option" ).find do |option|
      option.text == user.pay_card.expire_month
    end.click
    # selecting expiry year
    months = @browser.find_elements(:xpath, "//select[@name='expiryYear']").first
    months.find_elements( :tag_name => "option" ).find do |option|
      option.text == user.pay_card.expire_year
    end.click
    # filling security code
    get_elem_and_fill(
      :xpath, "//input[@maxlength='3']", user.pay_card.security_code
    )
    # filling cardholders name
    get_elem_and_fill(
      :xpath, "//input[@placeholder='e.g. John Smith']", user.pay_card.cardholder_name
    )
    # filling address 1
    get_elem_and_fill(
      :id, 'sa.nameAddressLine1', user.pay_card.adress_1
    )
    # filling address 2
    get_elem_and_fill(
      :id, 'sa.nameAddressLine2', user.pay_card.adress_2
    )
    # filling city
    get_elem_and_fill(
      :id, 'sa.nameCity', user.pay_card.city
    )
    # filling zip
    get_elem_and_fill(
      :id, 'sa.namePostcode', user.pay_card.zip
    )
    # selecting country
    countries = @browser.find_elements(:xpath, "//select[@id='sa.nameCountry']").first
    countries.find_elements( :tag_name => "option" ).find do |option|
      option.text == user.pay_card.country
    end.click

  end
  def accept_policy
    @browser.find_elements(:xpath, "//div[@class='terms']").first.click
  end
  def pay_now
    get_elem_and_click(:xpath, "//button[@ng-if='!pm.isMobile']")
  end
  def cookie_popup_close
    get_elem_and_click(:xpath, "//core-icon[@icon-id='glyphs.close']")
  end
  def check_payment_error
    title = get_element(:xpath, "//div[@ng-if='$ctrl.textTitle']")
    error_text = get_element(:xpath, "//div[@ng-if='$ctrl.text']")
    puts title.text
    puts  error_text.text
    return title.text, error_text.text
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
    @wait.until {@browser.find_element(by, value).displayed?}
    element = @browser.find_element(by, value); @wait.until { element.displayed?}
    if element
      return @browser.find_element(by, value)
    else
      raise "Element you have passed: #{value} with selector: #{by}"\
        " was not found on page in #{@wait.inspect} time"
    end
  end
end
class User
  attr_accessor :email, :password, :first_name, :surname, :title, :mobile_country,
    :mobile_phone, :pay_card
  def initialize(
      email, password, first_name, surname, title, mobile_country, mobile_phone, pay_card
    )
    @email = email
    @password = password
    @first_name = first_name
    @surname = surname
    @title = title
    @mobile_country = mobile_country
    @mobile_phone = mobile_phone
    @pay_card = pay_card
  end
end
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

# TEST
begin
  # ACTION
  # Desc: Creating user with his card
  # Exp: User is created
  UserA = User.new(
  email = 'l536270@mvrht.com', password = '12345678aA',
  first_name = 'Andrew', surname = 'Balboa', title = 'Mr',
  mobile_country = 'Poland', mobile_phone = '555555555',
  pay_card = PaymentCard.new(
      number = '5105105105105100', type = 'MasterCard',
      expire_month = '12', expire_year = '2020', security_code = '666',
      cardholder_name = "#{first_name} #{surname}",
      adress_1 = 'Katowice ul.Jana Pawla', adress_2 = '',
      city = 'Katowice', zip = '22-333', country = 'Poland'
    )
  )
  puts UserA.inspect
  puts UserA.pay_card.inspect
  # STEP
  # Desc: User open Browser and navigate to Ryanair main page
  # Exp: Ryanair main page should open in no longer than 15s
  puts "[TC STEP] - User go to: #{MAIN_PAGE}"
  web_browser = SeleniumBrowser.new
  web_browser.go_to MAIN_PAGE
  
  puts 'user close cookie disclaimer'
  web_browser.cookie_popup_close
  
  # STEP
  # Desc: User choose one-way ticket option
  # Exp: One-way field is correctly selected
  puts '[TC STEP] - User selects One-way ticket option'
  web_browser.choose_one_way
  # STEP
  # Desc: User select origin Airport
  # Exp: Airport is correctly selected field is correctly selected
  puts '[TC STEP] - User selects flight out airport'
  web_browser.select_origin(POLAND_XPATH, 'Katowice')
  # STEP
  # Desc: User select destination Airport
  # Exp: Airport is correctly selected field is correctly selected
  puts '[TC STEP] - User selects flight to airport'
  web_browser.select_destination(GRECE_XPATH, 'Chania')
  # STEP
  # Desc: User search for first avaiable flight
  # Exp: At least on flight should be found
  avaiable_days = []
  MONTHS.each do |month|
    puts "[TC STEP] - User search for flights in #{month}"
    avaiable_days = web_browser.find_avaiable_flights_in_month(month)
    break unless avaiable_days.nil?
  end
  # STEP
  # Desc: User choose first avaiable day in month and selects it.
  # Exp: Choosen day is correctly selected
  puts '[TC STEP] - User selects choosen day'
  choosen_day = avaiable_days.first
  choosen_day.click
  # STEP
  # Desc: User clicks 'Lets's go' button
  # Exp: User should be re-directed to booking home page in less than 15s
  puts "[TC STEP] - User clicks 'Lets's go' button."
  web_browser.lets_go
  puts "User waits for page to load."
  web_browser.wait_for_booking_page_load
  sleep 3
  # STEP
  # Desc: User select price
  # Exp: Selecting price should open avaiable plans for this flight
  web_browser.click_price
  sleep 4
  # STEP
  # Desc: User select first plan
  # Exp: After selecting first plan user should be redirected to page
  #      with 'Recommended for you' options
  puts '[TC STEP] - User selects flight plan'
  web_browser.countinue
  web_browser.wait_for_recommended_page_load
  sleep 2
  # STEP
  # Desc: User continues to next page
  # Exp: Summary page should load
  puts '[TC STEP] - User selects flight plan'
  web_browser.countinue
  puts 'check_out'
  web_browser.check_out
  puts 'pop up'
  web_browser.seat_popup_ok
  puts 'login'
  web_browser.login
  sleep 3
  puts 'filling User details form'
  web_browser.fill_user_form(UserA)
  puts 'accepting policy'
  web_browser.accept_policy
  #puts 'clickin PayNow button'
  #web_browser.pay_now
#  puts 'User looks for an error'
#  error_title, error_message = web_browser.check_payment_error
#  puts "error_title is same as expected" if error_title == 'Oh. There was a problem'
#  puts "error_message is same as expected" if error_message == 'As your payment was not authorised we could not complete your reservation. Please ensure that the information was correct or use a new payment to try again'
  
  puts 'END'
  sleep 1000
rescue Exception => e
  puts e
  puts e.class
ensure
  sleep 20
  web_browser.quit
end

