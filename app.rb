require 'sinatra'
require 'sinatra/json'
require 'yaml'
require 'haml'
require 'coffee-script'
require 'redis'

set :haml, format: :html5

get '/' do
  haml :index
end

get '/application.js' do
  coffee :application
end

get '/application.css' do
  scss :application
end

get '/databases' do
  json YAML::load(File.read('config.yml'))['default']['td']['databases']
end

get '/records/:type' do
  type = params[:type]
  redis_cli = Redis.new

  keys = redis_cli.keys("#{type}-*")

  result = {}
  keys.each do |date|
    result[date.gsub(/#{type}-/, '')] = redis_cli.get(date).to_i
  end

  json result
end

get '/elapsed' do
  redis_cli = Redis.new

  keys = redis_cli.keys('job-*')
  result = {}

  keys.sort.last(10000).each do |date|
    d = instance_eval redis_cli.get(date)
    result[date.gsub(/job-/, '')] = d if d[:elapsed]
  end

  json result
end

get '/running' do
  redis_cli = Redis.new
  redis_cli.get('running')
end
