MusicMonitor
============

MusicMonitor watches MPD to displays track notifications via Growl
and provide scrobbling.

Requirements
------------

To run MusicMonitor, you'll need the following gems:

* [librmpd][]
* [meow][]
* [ruby-aaws][]
* [scrobbler][]

[librmpd]: http://librmpd.rubyforge.org/
[meow]: http://meow.rubyforge.org/
[ruby-aaws]: http://www.caliban.org/ruby/ruby-aws/
[scrobbler]: http://scrobbler.rubyforge.org/

Usage
-----

Just run 

	musicmonitor &
	
in the terminal. A proper daemon mode will be implemented in the future.

If you want to use album art, you'll need to create a file with your Amazon
Developer's Key in it at `~/.amazonkey`.

You can do this on the command line with:

	echo 'MYAMAZONKEY' > ~/.amazonkey

...or just by using your favorite text editor.

You'll also need to put your last.fm credentials in a file at `~/.lastfm` in
the following format:

	username
	password

The password can also be an md5 hash rather than plain text.
