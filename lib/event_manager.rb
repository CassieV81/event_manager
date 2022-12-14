require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone(phone)
  phone = phone.tr('^0-9', '')
  if phone.length == 10
    puts phone
  elsif phone.length == 11 && phone[0] == "1"
     puts phone[1, 10]
  else
    puts "N/A"
  end
end

def peak_hours(peak_time)
  # puts peak_time
  hour = Time.strptime(peak_time, '%m/%d/%y %k:%M').strftime('%k')
  puts hour
end

def peak_days(peak_day)
  day = Time.strptime(peak_day, '%m/%d/%y %k:%M').strftime('%A')
  puts day
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone = clean_phone(row[:homephone])
  peak_time = peak_hours(row[:regdate])
  peak_day = peak_days(row[:regdate])

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end