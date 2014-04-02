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

    def jobs
      @client.jobs(0, 1000)
    end

    def databases
      @client.databases
    end
  end
end

def save(jobs)
  redis_cli = Redis.new
  jobs.each do |job|
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

def count_and_save(jobs, type)
  result = {}

  jobs.each do |job|
    if job.start_at
      time = job.start_at.change(min: 0, sec: 0).to_i
      result[time] ? (result[time] += 1) : (result[time] = 1)
    end
  end

  redis_cli = Redis.new
  result.each {|key, value| redis_cli.set "#{type}-#{key}", value }
end

def aggregate
  td_cli = TdStats::Client.new
  jobs = td_cli.jobs

  save(jobs)

  count_and_save(jobs, 'all')
  count_and_save(jobs.select{|job| job.status == 'error' }, 'error-all')

  td_cli.databases.map(&:name).each do |database|
    count_and_save(jobs.select {|job| job.db_name == database }, "#{database}")
    count_and_save(jobs.select {|job| job.status == 'error' && job.db_name == database }, "error-#{database}")
  end
end

def save_records
  td_cli = TdStats::Client.new
  redis_cli = Redis.new

  td_cli.databases.each {|database| redis_cli.set "count-#{database.name}-#{Time.now.to_i}", database.count }
end
