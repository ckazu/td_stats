every 50.minute do
  rake 'aggregate:records'
  rake 'aggregate:jobs'
end

every 10.minute do
  rake 'aggregate:running_jobs'
end
