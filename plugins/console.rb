# A really simple example plugin.
class MusicMonitor::Console < MusicMonitor::Plugin
	# Print a now playing message to the terminal.
	def notify(title, song)
		puts "Now Playing: #{title} - #{song.album} by #{song.artist}"
	end
end
