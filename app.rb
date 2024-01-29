require "sinatra"
require "sinatra/reloader"
require "http"

get("/") do
  erb(:homepage)
end

get("/umbrella") do
  erb(:umbrella_form)
end

post("/process_umbrella") do
  @user_loc = params["user_loc"]
  input_location_no_space = @user_loc.gsub(" ", "%20")

  gmaps_api_key = ENV.fetch("GMAPS_KEY")
  gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{input_location_no_space}&key=#{gmaps_api_key}"
  raw_gmaps_resp = HTTP.get(gmaps_url)
  parsed_gmaps_response = JSON.parse(raw_gmaps_resp.to_s)

  location_hash= parsed_gmaps_response.dig("results", 0, "geometry", "location")
  @latitude = location_hash["lat"]
  @longitude = location_hash["lng"]

  pirate_weather_api_key = ENV.fetch("PIRATE_WEATHER_KEY")
  weather_url = "https://api.pirateweather.net/forecast/#{pirate_weather_api_key}/#{@latitude},#{@longitude}"
  raw_weather_resp = HTTP.get(weather_url)
  parsed_weather_response = JSON.parse(raw_weather_resp.to_s)

  current_weather_hash = parsed_weather_response["currently"]
  @current_temp = current_weather_hash["temperature"]
  @current_summary = current_weather_hash["summary"]

  hourly_weather_hash = parsed_weather_response["hourly"]
  hourly_weather_hash_data = hourly_weather_hash["data"]
  forecast_array = []
  (0..12).each { |hour|
    data_for_hour = hourly_weather_hash_data[hour]
    probability = data_for_hour["precipProbability"]
    forecast_array.push(probability)
  }

  umbrella_flag = false
  forecast_array.each { |probability|
    if probability >= 0.1
      umbrella_flag = true
      break
    end
  }
  if umbrella_flag
    @umbrella = "You might want to take an umbrella!"
  else
    @umbrella = "You probably won't need an umbrella"
  end

  erb(:umbrella_results)
end
