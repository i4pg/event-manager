# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def peak_day(dates)
  max_days = dates.map do |date|
    Time.strptime(date, '%Y/%d/%m %k:%M').strftime('%A')
  end

  max_days = max_days.each_with_object({}) do |curr, acc|
               if !acc[curr]
                 acc[curr] = 1
               else
                 acc[curr] += 1
               end
             end.sort_by { |_key, value| value }
  puts "the most regesterd day is #{max_days.last[0]}, which has #{max_days.last[1]} regesterd people"
end

def peak_hour(hours)
  max_reg = hours.map do |hour|
    Time.strptime(hour, '%Y/%d/%m %k:%M').strftime('%k.%M').to_f.round
  end

  max_reg = max_reg.each_with_object({}) do |curr, acc|
    if !acc[curr]
      acc[curr] = 1
    else
      acc[curr] += 1
    end
  end.sort_by { |_key, value| value }
  puts "The peak hour is #{max_reg.last[0]} which has #{max_reg.last[1]} regesterd people"
end

def gets_phone_number(phone_number)
  phone_number = phone_number.tr('^0-9', '')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11
    phone_number.slice(1, 10) if phone_number[0].to_i == 1.to_i
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
dates = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = gets_phone_number(row[:homephone])
  dates.push(row[:regdate])

  # legislators = legislators_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)
end
peak_hour(dates)
peak_day(dates)
