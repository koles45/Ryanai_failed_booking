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
PRICE_FROM = '#flight-FR\7e 7006\7e \20 \7e \7e KTW\7e 04\2f 01\2f 2017\20 11\3a 40\7e CHQ\7e 04\2f 01\2f 2017\20 15\3a 20\7e > div > div.flight-header__min-price > flights-table-price > div'
class SeleniumBrowser
  def initialize
    chromedriver_path = File.join('driver', 'chromedriver.exe')
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
  def click_price
    get_elem_and_click(:xpath, "//*[contains(text(), 'from')]")
  end
  def countinue
    get_elem_and_click(:id, 'continue')
  end
  def check_out
    get_elem_and_click(:xpath, "//*[contains(text(), 'Check out')]")
  end
  def seat_popup_ok
    get_elem_and_click(:xpath, "//*[contains(text(), 'Ok, thanks')]")
  end
  private
  def get_elem_and_click(by, value)
    get_element(by, value).click
  end
  def get_element(by, value)
    element = @browser.find_element(by, value); @wait.until { element.displayed?}
    if element
      return @browser.find_element(by, value)
    else
      raise "Element you have passed: #{value} with selector: #{by}"\
        " was not found on page in #{@wait.inspect} time"
    end
  end
end
# initialization of browser
begin
  web_browser = SeleniumBrowser.new
  web_browser.go_to MAIN_PAGE
  web_browser.choose_one_way
  web_browser.select_origin(POLAND_XPATH, 'Katowice')
  web_browser.select_destination(GRECE_XPATH, 'Chania')
  avaiable_days = []
  MONTHS.each do |month|
    avaiable_days = web_browser.find_avaiable_flights_in_month(month)
    break unless avaiable_days.nil?
  end
  # STEP
  # Desc: User choose first avaiable day in month and selects it.
  # 
  choosen_day = avaiable_days.first
  choosen_day.click
  sleep 2
  # STEP
  # Desc: User clicks 'Lets's go' button
  web_browser.lets_go
  sleep 5
  web_browser.click_price
  
  web_browser.countinue
  sleep 1
  web_browser.countinue
  
  sleep 2
rescue Exception => e
  puts e
  puts e.class
ensure
  sleep 2
  web_browser.quit
end

