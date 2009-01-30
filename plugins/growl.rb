class MusicMonitor::Growl < MusicMonitor::Plugin
	require 'album_art'
	include MusicMonitor

	def initialize
		# Setup Growl
		@default_icon = '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarMusicFolderIcon.icns'
	end

	# Send a notification to Growl.
	def notify(title, song)
		escaped_title = title.escape_for_terminal

		if song['album'] and song['artist']
			message = song['album'] + ' - ' + song['artist']
		else
			message = song['album'] || song['artist']
		end

		return false unless message
		@icon = @default_icon.dup unless @icon
		message = message.escape_for_terminal
		icon = @icon.escape_for_terminal

		command = "growlnotify '#{escaped_title}' -m '#{message}' -n MusicMonitor -w --image '#{icon}'"
		IO.popen(command)
	end

	# Update the album art
	def song_changed(new_song)
		# Get album art
		art = AlbumArt.new new_song.album, new_song.artist
		@icon = (art.file) ? art.file : @default_icon
	end
end

class String
	# Escape single quotes
	def escape_for_terminal
		self.gsub(/'/, "'\\\\\''")
	end
end
