#!/usr/bin/env ruby
require 'rubygems'
require 'AWS'

# Set to nil to run on all volumes, an array to run multiple volumes, or a string to run a single volume
VOLUME_ID = nil
AWS_ACCESS_KEY_ID = nil
AWS_SECRET_ACCESS_KEY = nil

# How many hourly snapshots to keep
NUM_HOURLIES = 168
# How many daily snapshots to keep
NUM_DAILIES = 30
# How many weekly snapshots to keep
NUM_WEEKLIES = 26

ec2 = AWS::EC2::Base.new(:access_key_id => AWS_ACCESS_KEY_ID, :secret_access_key => AWS_SECRET_ACCESS_KEY)
current_snapshots = ec2.describe_snapshots( :owner => 'self' )

DAY_FORMAT = "%Y%m%d"
WEEK_FORMAT = "%Y%U"
NOW = Time.now.to_i

# Convert the number of hourlies to be kept into the last hourly timestamp
LAST_HOURLY = NOW - ( NUM_HOURLIES * 60 * 60 )
# Convert the number of dailies to be kept into the last day to keep (formatted as above, e.g., 20101201 for Dec 12, 2010)
LAST_DAILY = Time.at( LAST_HOURLY - ( NUM_DAILIES * 24 * 60 * 60 ) ).strftime( DAY_FORMAT ).to_i
# Convert the number of weeklies to be kept into the last week to keep (formatted as above, e.g. 201005 for the 5th week of 2010)
# There will be some overlap between the last week of one year and the first week of another
LAST_WEEKLY = Time.at( LAST_HOURLY - ( NUM_DAILIES * 24 * 60 * 60 ) - ( NUM_WEEKLIES * 7 * 24 * 60 * 60 ) ).strftime( WEEK_FORMAT ).to_i

snapshots_by_volume = {}

# Grab all the snapshots for this account and order them by volume
current_snapshots['snapshotSet']['item'].each do |snap|
  next unless snap['status'] == 'completed'
  
  snapshots_by_volume[snap['volumeId']] = [] unless snapshots_by_volume.has_key?( snap['volumeId'] )
  time = Time.parse snap['startTime']
  
  snapshots_by_volume[snap['volumeId']].push( {
    :snapshot_id => snap['snapshotId'],
    :timestamp => time.to_i,
    :day => time.strftime( DAY_FORMAT ).to_i,
    :week => time.strftime( WEEK_FORMAT ).to_i,
    :started_at => snap['startTime']
  })
end

volumes = VOLUME_ID.nil? ? snapshots_by_volume.keys : ( VOLUME_ID.is_a?( Array ) ? VOLUME_ID : [ VOLUME_ID ] )
volumes.each do |v|
  next unless snapshots_by_volume.has_key? v #skip if this volume doesn't have any snapshots
  
  # These arrays need to be inside the block of code that iterates through volume IDs otherwise bad things happen!
  days_kept = []
  weeks_kept = []

  snapshots_by_volume[v].sort! { |x,y| y[:timestamp] <=> x[:timestamp] } #sort this volume's snapshots by newest to oldest
  snapshots_by_volume[v].each do |snap|
    # This snapshot is within the accepted hourly range and will be kept
    if snap[:timestamp] >= LAST_HOURLY
      # Logging action goes here
      puts "Hourly: #{ snap[:snapshot_id] } : #{ snap[:started_at] }"
    
    # This snapshot is within the accepted daily range, only keep it if a newer log for this day has not already been added
    elsif snap[:day] >= LAST_DAILY && !days_kept.include?( snap[:day] )
      days_kept.push snap[:day] #add this snapshot to the included day array so subsequent snapshots for this day aren't kept
      # Logging action goes here
      puts "Daily: #{ snap[:snapshot_id] } : #{ snap[:started_at] }"
    
    # This snapshot is within the accepted weekly range, only keep it if a newer log for this week has not already been added
    elsif snap[:week] >= LAST_WEEKLY && !weeks_kept.include?( snap[:week] )
      weeks_kept.push snap[:week] #add this snapshot to the included week array so subsequent snapshots for this week aren't kept
      # Logging action goes here
      puts "Weekly: #{ snap[:snapshot_id] } : #{ snap[:started_at] }"
    
    # This snapshot should be removed
    else
      begin
        ec2.delete_snapshot( :snapshot_id => snap[:snapshot_id] )
        # Logging action goes here
        puts "Delete: #{ snap[:snapshot_id] } : #{ snap[:started_at] }"
      rescue
        puts "Could not delete #{ snap[:snapshot_id] }"
      end
    end
  end
end