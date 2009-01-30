class MusicMonitor::LastFM < MusicMonitor::Plugin
	include MusicMonitor

	require 'scrobbler'

	def initialize(config_file='~/.lastfm')
		@scrobbles = []
		@lastfm_playing_sent = false
		@lastfm_can_scrobble = false

		# Load last.fm credentials
		debug 'Loading last.fm config... ', false
		config_file = File.expand_path(config_file)
		if File.exists? config_file
			lines = []

			File.open(config_file, 'r').each do |l|
				lines << l.chomp
			end

			user, password = lines
		else
			puts 'Missing last.fm credentials at ' + config_file
		end

		debug 'Done'

		# Connect to last.fm
		debug 'Connecting to last.fm... ', false
		@lastfm = Scrobbler::SimpleAuth.new(:user => user, :password => password)
		@lastfm.handshake!
		debug @lastfm.status
	end

	# Scrobble queued tracks
	def submit_scrobbles
		if @lastfm and @lastfm.status == 'OK'
			@scrobbles.each do |scrobble|
				if submit scrobble
					debug "#{scrobble.track} submitted to last.fm"
					@scrobbles.delete(scrobble)
				else
					debug "Failed submitting #{scrobble}"
				end
			end
		end
	end

	def update(song, elapsed)
		# Only scrobble if connected to last.fm and the
		# track has an artist and name
		if @lastfm and @lastfm.status == 'OK' and
			song['artist'] and song['title']

			# Only scrobble tracks that are longer than 30 seconds.
			if song['time'].to_i > 30

				# Don't send multiple times, or if we haven't played more
				# than the @scrobble_time.
				if !@lastfm_can_scrobble and (@scrobble_time - elapsed) <= 0

					@scrobbles.push lastfm_scrobble(song)

					# Scrobbles aren't sent immediately,
					# they're sent when the song changes.

					@lastfm_can_scrobble = true
				end
			end

			# Don't send multiple times
			if !@lastfm_playing_sent
				lastfm_play song
				@lastfm_playing_sent = true
			end
		end
	end

	# Reset temporary variables and submit queued scrobbles.
	def song_changed(new_song)
		# Reset temporary song variables
		@lastfm_playing_sent = false
		@lastfm_can_scrobble = false
		@scrobble_time = [new_song.time.to_i / 2, 240].min
		@started_playing = Time.new

		submit_scrobbles
	end

	# Tell last.fm what's playing.
	def lastfm_play(song)
		playing = Scrobbler::Playing.new(
			:session_id => @lastfm.session_id,
			:now_playing_url => @lastfm.now_playing_url,
			:artist => song['artist'],
			:track => song['title'],
			:album => song['album'],
			:length => song['time'],
			:track_number => song['track']
		)

		# Send now playing information immediately
		submit playing
		playing
	end

	# Create a Scrobbler::Scrobble object
	def lastfm_scrobble(song)
		Scrobbler::Scrobble.new(
			:session_id => @lastfm.session_id,
			:submission_url => @lastfm.submission_url,
			:artist => song['artist'],
			:track => song['title'],
			:album => song['album'],
			:time => @started_playing,
			:length => song['time'],
			:track_number => song['track']
		)
	end

	def submit(scrobble)
		retries = 0
		begin
			scrobble.submit!
			return true
		rescue BadSessionError
			debug "(BadSessionError: Retry #{retries})"
			if retries += 1 < 5
				debug "Reconnecting to last.fm... (Retry #{retries})"
				sleep 2 if retries > 2
				# Reconnect to last.fm
				@lastfm.handshake!
				retry
			else
				debug "Scrobble failed. (#{retries} retries)"
				return false
			end
		end
	end
end

# Code copied from Scrobbler 0.2.2
# <http://scrobbler.rubyforge.org/>
module Scrobbler
	class SimpleAuth

		# Override to enable authentication using pre-hashed passwords.
		# Won't work if a user's un-hashed password looks a hash.
		def handshake!
			# Begin edits
			require 'digest/md5'

			if @password =~ /^[0-9a-f]{32}$/i
				password_hash = @password
			else
				password_hash = Digest::MD5.hexdigest(@password)
			end
			# End edits

			timestamp = Time.now.to_i.to_s
			token = Digest::MD5.hexdigest(password_hash + timestamp)

			query = { :hs => 'true',
					  :p => AUTH_VER,
					  :c => @client_id,
					  :v => @client_ver,
					  :u => @user,
					  :t => timestamp,
					  :a => token }
			result = @connection.get('/', query)

			@status = result.split(/\n/)[0]
			case @status
			when /OK/
				@session_id, @now_playing_url, @submission_url = result.split(/\n/)[1,3]
			when /BANNED/
				raise BannedError # something is wrong with the gem, check for an update
			when /BADAUTH/
				raise BadAuthError # invalid user/password
			when /FAILED/
				raise RequestFailedError, @status
			when /BADTIME/
				raise BadTimeError # system time is way off
			else
				raise RequestFailedError
			end
		end
	end
end
