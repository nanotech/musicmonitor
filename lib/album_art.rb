# Downloads album art from Amazon
class AlbumArt
	attr_reader :file

	def initialize(album, artist, opts={})
		album = album.to_s
		artist = artist.to_s

		return if album.empty? and artist.empty?

		default_opts = {
			# Where your album art is stored
			:art_folder => '~/.albumart/',
			# Location of your Amazon Developer's Key
			:amazon_key_path => '~/.amazonkey',
			# Formats that this script will recognise and try to use
			:art_formats => ['jpg', 'png'],
			# Valid names for art files
			:possible_filenames => filenames(album, artist),
			# Invalid characters to be removed
			:invalid_chars => ['/', '\\', ':'],
		}

		# Set default options, but have user-set options
		# overwrite the defaults.
		opts = default_opts.merge(opts)

		# Expand paths to absolute paths
		art_folder = File.expand_path(opts[:art_folder]) + '/'
		amazon_key_path = File.expand_path(opts[:amazon_key_path])

		# Loop through possible file names and accepted formats,
		# and exit if the artwork already exists.
		opts[:possible_filenames].each do |filename|
			opts[:art_formats].each do |ext|
				opts[:invalid_chars].each do |char|
					filename = filename.gsub(char, '_')
				end
				@file = "#{art_folder}#{filename}.#{ext}"
				return if File.exists? @file
				@file = nil # nothing found
			end
		end

		# Load your Amazon Key
		if File.exists? amazon_key_path
			File.open(amazon_key_path, 'r').each do |l|
				@amazon_key = l.chomp
			end
		end

		if !@amazon_key
			puts "Missing Amazon Developer's key, can't get artwork."
			return
		end

		# Only load the amazon gem if we need it, which we do by now.

		begin
			require 'amazon/aws/search'
			self.class.class_eval do
				include Amazon::AWS
				include Amazon::AWS::Search
			end
		rescue LoadError
			require 'rubygems'
			retry
		end


		# Setup query
		query = ItemSearch.new('Music', { 'Title' => album, 'Artist' => artist })
		rgroup = ResponseGroup.new(:Images)
		request = Request.new(@amazon_key)

		# Query Amazon
		begin
			response = request.search(query, rgroup)
		rescue
			return
		end

		# Get the url of the image
		begin
			url = response.item_search_response.items[0].item[0].large_image.url
		rescue NoMethodError
			return
		end

		# Download the image
		data = Net::HTTP.get_response(URI.parse(url))

		@file = filename(album, artist, '.jpg', art_folder)

		# Save the image
		File.open(@file, 'wb') do |f| 
			f << data.body
			f.flush
		end
	end

	def filename(album, artist, postfix='', prefix='')
		file = if album.empty?
				   artist
			   elsif artist.empty?
				   album
			   else
				   album + " - " + artist
			   end

		prefix + file + postfix
	end

	def filenames(album, artist, *args)
		[[album, artist], [album, ''], ['', artist]].map do |x|
			filename *x.concat(args)
		end
	end
end
