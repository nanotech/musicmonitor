MusicMonitor
============

Requirements
------------

To run MusicMonitor, you'll need the following gems:

* [librmpd][]
* [meow][]
* [ruby-aaws][]

[librmpd]: http://librmpd.rubyforge.org/
[meow]: http://meow.rubyforge.org/
[ruby-aaws]: http://www.caliban.org/ruby/ruby-aws/

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
