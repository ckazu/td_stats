every 50.minute do
  rake 'aggregate:records'
  rake 'aggregate:jobs'
end
