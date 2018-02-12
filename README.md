# Gencon Housing Portal script

## Background

### GenCon & Housing Shortages

GenCon is an annual board gaming event at the Indianapolis Convention Center that draws over 70,000 attendees. Downtown Indianapolis only has about 7,500 hotel rooms, though. This is hardly enough to accommodate everyone.

To solve this issue, GenCon uses a housing lottery system, where every hotel in the city dedicates most of their rooms to a housing block. And attendees are assigned a random time on a specific day at which they can access a Housing Portal to book one of these hotel rooms.

Generally, downtown hotels book within hours, leaving tens of thousands of attendees to deal with hotel rooms miles away, requiring a 15-20 minute drive twice per day, and high parking fees.

### The Problem

Every now and then, someone will cancel a downtown hotel room booking. It could be for a variety of reasons, like they had to cancel their trip, or their group booked multiple hotel rooms just to make sure they claimed a spot in the cutthroat lottery.

But, with so many people scouring the housing portal for these rooms, you need to be insanely lucky to be on the site at just the right time to grab one of these rooms when they become available.

### A New Hope

So how can you increase your odds of grabbing one of these rooms?

Luckily, we can automate a script that checks the site every minute and then alerts you to any available rooms matching your search preferences.

## The Script

### Installation

First, make sure you have Ruby v2.4.1 or greater.

Then, clone the repo and install the needed gems

```
git clone git@github.com:daybreaker/gencon.git

gem install bundler

bundle install
```

### Running the script

Go the GenCon Housing Portal which looks like "https://aws.passkey.com/reg/XXXXXXX-XXXX/null/null/1/0/null" and find the value that replaces `XXXXXXX-XXXX`. This is your personal housing portal key.

The script runs on the command line like:

`ruby portal.rb --key XXXXXXX-XXXX`

There are several options you can add, like:

```
-k, --key                        Your portal key (required)
-a, --show_all   default: false  Show All Hotels (default only shows downtown hotels)
-w, --wednesday  default: false  Set checkin day to Wednesday (default is Thursday)
-m, --monday     default: false  Set checkout day to Monday (default is Sunday)
-c, --connected  default: false  Only look for Skywalk connected hotels
--max_distance                   How far to search (ie: within 8 blocks)
--miles          default: false  Use miles instead of blocks for the search
--checkin                        Set a specific checkin day in YYYY-MM-DD format
--checkout                       Set a specific checkout day in YYYY-MM-DD format
-t, --minutes    default: 1      How often to search, in minutes
-b, --browser    default: false  If results are found, open a browser window to the portal
```

Anything with a default of false means you dont need to include a value after using the flag, just use the flag. Everything else requires a value after the flag.

A sample call is:

```
ruby portal.rb --key XXXXXXX-XXXX -awmb --max_distance 12 --miles
```

Which will show all hotels (`-a`) within 12 miles (`--max_distance 12 --miles`), checking in on wednesday (`-w`) and checking out on monday (`-m`), and opening a browser window if it finds results (`-b`).

## Future Plans & Missing features

This script is based off a similar [python script](https://github.com/mrozekma/gencon-hotel-check). That script has additional features like a RegEx search to look only for certain room types or hotels, a budget search to filter out expensive rooms, and various alert methods, like email, or a system popup.

In the future, I'll be adding the following:

- [ ] Max room cost
- [ ] Room Type search (ie: queen, king, suite, etc)
- [ ] Hotel Name filter (ie: Marriott, Alexander, etc)
- [ ] System Pop Up Alert
- [ ] SMS text alert

## Contributing

Feel free to make a pull request to add new features or fix bugs, if you want. Clone the repo, make a branch, then submit a PR from that branch into master.
