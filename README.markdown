# Rotate EBS Snapshots #

This is a Ruby-based script that will rotate your EBS snapshots in the [Grandfather-Father-Son](http://en.wikipedia.org/wiki/Grandfather-father-son_backup) style.  It was originally designed to keep one week's worth of hourly snapshots, followed by the next 30 days worth of daily snapshots, followed by the next 26 weeks worth of weekly snapshots.  These numbers are easily modified in the rotate.rb file.  The important note is that the daily range does not start until the hourly ends, just as the weekly range doesn't start until the daily ends.  Thus, this sample setup will store 224 snapshots covering the last 219 days.

This script is designed to run as a cron job.  While initially setup to run according to my personal needs, the rotation frequency should be pretty simple to update / extend (adding months after weeks, and/or years after months).

Searching for an easy way to rotate my EBS snapshots led me to a couple of scripts which inspired this code. [This one](http://www.kloppmagic.ca/blog/2010/09/rotating-ebs-snapshots/) by [Stefan Klopp](http://www.kloppmagic.ca/about) (PHP-based) and [this one](https://github.com/timoteo/ebs_snapshot_pruning/blob/master/prune_ebs_snapshots.rb) by [Timo](https://github.com/timoteo) (Ruby-based).

Each user will need to update the logging section to fit his/her specific needs.


**Dependencies**

This script depends upon the [amazon-ec2 gem](http://github.com/grempe/amazon-ec2/tree/master).