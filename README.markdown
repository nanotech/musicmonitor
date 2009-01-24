MusicMonitor
============

MusicMonitor watches MPD to displays track notifications via Growl
and provide scrobbling.

Requirements
------------

To run MusicMonitor, and all it's plugins, you'll need the following:

* [librmpd][] gem (Core)
* [ruby-aaws][] gem (Growl, album art)
* [growlnotify][] (Growl)
* [scrobbler][] gem (LastFM)

[librmpd]: http://librmpd.rubyforge.org/
[ruby-aaws]: http://www.caliban.org/ruby/ruby-aws/
[growlnotify]: http://growl.info/
[scrobbler]: http://scrobbler.rubyforge.org/

Usage
-----

Just run 

	musicmonitor &
	
in the terminal. A proper daemon mode will be implemented in the future.

You can also add the `--verbose` flag to see more information about
what's actually going on.

Plugins
-------

If you want to disable a plugin, just move it out of the plugins directory,
or change the file extension to something other than ".rb".

### Growl ###

If you want to use album art, you'll need to create a file with your Amazon
Developer's Key in it at `~/.amazonkey`.

You can do this on the command line with:

	echo 'MYAMAZONKEY' > ~/.amazonkey

...or just by using your favorite text editor.

### LastFM ###

For scrobbling support, you'll need to put your last.fm credentials in a file
at `~/.lastfm` in the following format:

	username
	password

The password can also be an md5 hash rather than plain text.
