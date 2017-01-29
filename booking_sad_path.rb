require Dir.pwd + '/test_helper.rb'

start_time = Time.now
# Desc: This test case is designet to automate booking payment
# =>    on: https://www.ryanair.com/ie/en/
# =>    User inputs all needed data but uses invalid card number
# =>    Booking should be rejected with error
begin
  # ACTION
  # Desc: Creating user with his card
  # Exp: User is created
  UserA = User.new(
    'l536270@mvrht.com', '12345678aA', first_name = 'Andrew',
    surname = 'Balboa', 'Mr', 'Poland', 555_555_555,
    PaymentCard.new(
      510_510_510_510_510_0, 'MasterCard', '12', '2020', 666,
      "#{first_name} #{surname}", 'Katowice ul.Jana Pawla', '7/10',
      'Katowice', '22-333', 'Poland'
    ),
    'Poland', 'Katowice', 'Greece', 'Chania'
  )
  # STEP
  # Desc: User open Browser and navigate to Ryanair main page
  # Exp: Ryanair main page should open in no longer than 15s
  web_browser = SeleniumBrowser.new
  puts "[TC STEP] - User go to: #{MAIN_PAGE}"
  web_browser.go_to MAIN_PAGE
  # STEP
  # Desc: Checking if page was opened
  # Exp: Page url shoul match with MAIN_PAGE url
  assert "Page url asssertion=> RECEIVED: '#{web_browser.actual_url}'"\
    " | EXPECTED: '#{MAIN_PAGE}'", web_browser.actual_url == MAIN_PAGE
  # STEP
  # Desc: User close cookie information bar
  # Exp: Bar is closed
  puts '[TC STEP] - User close cookie disclaimer'
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
  web_browser.select_origin(
    UserA.travel_from_country, UserA.travel_from_city
  )
  # STEP
  # Desc: User select destination Airport
  # Exp: Airport is correctly selected field is correctly selected
  puts '[TC STEP] - User selects flight to airport'
  web_browser.select_destination(
    UserA.travel_to_country, UserA.travel_to_city
  )
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
  puts '[TC STEP] - User selects random day'
  choosen_day = avaiable_days.sample
  choosen_day.click
  # STEP
  # Desc: User clicks 'Lets's go' button
  # Exp: User should be re-directed to booking home page in less than 15s
  puts "[TC STEP] - User clicks 'Lets's go' button."
  web_browser.lets_go
  puts 'User waits for page to load.'
  web_browser.wait_for_booking_page_load
  # STEP
  # Desc: User select price
  # Exp: Selecting price should open avaiable plans for this flight
  puts '[TC STEP] - User selects price'
  web_browser.click_price
  # STEP
  # Desc: User select first plan
  # Exp: After selecting first plan user should be redirected to page
  #      with 'Recommended for you' options
  puts '[TC STEP] - User selects flight plan'
  web_browser.countinue
  puts 'waiting for page to load'
  web_browser.wait_for_recommended_page_load
  # STEP
  # Desc: User continues to next page
  # Exp: Summary page should load
  puts '[TC STEP] - User continues to next page'
  web_browser.countinue
  # STEP
  # Desc: User press the check out button
  # Exp: A pop up should appear with seat selection
  puts '[TC STEP] - User check out his flight'
  web_browser.check_out
  # STEP
  # Desc: User login to his account
  # Exp: User is correctly logged in
  puts '[TC STEP] - User log into his account'
  web_browser.login(UserA)
  # STEP
  # Desc: User fills details form
  # Exp: Form is filled
  puts '[TC STEP] - User fill details page'
  web_browser.fill_user_form(UserA)
  # STEP
  # Desc: User accepts terms and conditions
  # Exp: Check box is checked
  puts '[TC STEP] - User accept terms'
  web_browser.accept_policy
  # STEP
  # Desc: User finishes booking by clicking PayNow button
  # Exp: Error should be displayed indicating that payement
  #      was rejected (card not authorized)
  puts '[TC STEP] - User clicks PayNow button'
  web_browser.pay_now
  puts 'MAIN ASSERTION'
  error_title, error_message = web_browser.check_payment_error
  assert "Error_title assertion=> RECEIVED: '#{error_title}'"\
    " | EXPECTED: #{EXP_ERROR_TITLE}", error_title == EXP_ERROR_TITLE
  assert "Error_message assertion=> RECEIVED: '#{error_message}'"\
    " | EXPECTED: '#{EXP_ERROR_MSG}'", error_message == EXP_ERROR_MSG
  puts "END of Test Case. Duration: #{(Time.now - start_time).to_i}s"
  sleep 2
rescue => e
  puts "RunTimeError: #{e}"
  puts e.class
  raise e.backtrace.join
ensure
  sleep 2
  web_browser.quit
end
