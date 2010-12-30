# Rotate EBS Snapshots #

This script is designed to run as a cron job.  This was initially setup to run according to my personal needs, but the frequency of updates should be pretty simple to update / extend.

Searching for an easy way to rotate my EBS snapshots led me to a couple of scripts which inspired this code. [This one](http://www.kloppmagic.ca/blog/2010/09/rotating-ebs-snapshots/) by [Stefan Klopp](http://www.kloppmagic.ca/about) and [this one](https://github.com/timoteo/ebs_snapshot_pruning/blob/master/prune_ebs_snapshots.rb) by [Timo](https://github.com/timoteo).

Each user will need to update the logging section to fit the specific needs.

**Dependencies**

This script depends upon the [amazon-ec2 gem](http://github.com/grempe/amazon-ec2/tree/master).