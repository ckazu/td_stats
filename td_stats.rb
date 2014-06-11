require 'active_support/core_ext'
require 'td-client'
require 'redis'
require 'yaml'
require 'json'
require 'pp'

class TdStats
  class Client
    def initialize
      config = YAML::load(File.read('config.yml'))['default']
      @client = TreasureData::Client.new config['td']['apikey']
    end

    def jobs(opts={})
      @client.jobs(0, 1000, opts)
    end

    def databases
      @client.databases
    end
  end
end

def save_jobs
  td_cli = TdStats::Client.new
  redis_cli = Redis.new
  td_cli.jobs.each do |job|
    value = {
      job_id: job.job_id,
      db_name: job.db_name,
      status: job.status,
      start_at: job.start_at.to_i,
      end_at: job.end_at.to_i,
      elapsed: (job.end_at ? job.end_at - job.start_at : nil)
    }
    redis_cli.set("job-#{job.job_id}", value)
  end
end

def count_and_save
  # [FIXME] should not check 'all' data
  result = {}
  error = {}

  # [ToDo] refactor
  redis_cli = Redis.new
  redis_cli.keys("job-*").each do |key|
    job = instance_eval(redis_cli.get key)
    if job[:start_at]
      result[job[:db_name]] = {} unless result.has_key? job[:db_name]
      error[job[:db_name]] = {} unless error.has_key? job[:db_name]
      time = Time.at(job[:start_at]).change(min: 0, sec: 0).to_i
      result[job[:db_name]][time] ? (result[job[:db_name]][time] += 1) : (result[job[:db_name]][time] = 1)
      if job[:status] == 'error'
        error[job[:db_name]][time] ? (error[job[:db_name]][time] += 1) : (error[job[:db_name]][time] = 1)
      end
    end
  end

  # [ToDo] refactor
  all = {}
  result.each do |db_name, values|
    values.each do |time, value|
      redis_cli.set("#{db_name}-#{time}", value)
      all[time] ? (all[time] += value) : (all[time] = value)
    end
  end
  all.each {|time, value| redis_cli.set("all-#{time}", value) }

  all = {}
  error.each do |db_name, values|
    values.each do |time, value|
      redis_cli.set("error-#{db_name}-#{time}", value)
      all[time] ? (all[time] += value) : (all[time] = value)
    end
  end
  all.each {|time, value| redis_cli.set("error-all-#{time}", value) }
end

def aggregate
  save_jobs
  count_and_save
rescue => e
  puts e
end

def save_records
  td_cli = TdStats::Client.new
  redis_cli = Redis.new

  td_cli.databases.each {|database| redis_cli.set "count-#{database.name}-#{Time.now.to_i}", database.count }
end

def running_jobs
  td_cli = TdStats::Client.new
  redis_cli = Redis.new

  redis_cli.set('running', td_cli.jobs(state='running').count)
end
