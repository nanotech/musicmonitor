# Downloads album art from Amazon
class MusicMonitor::AlbumArt
	attr_reader :file

	require 'amazon/aws/search'
	include Amazon::AWS
	include Amazon::AWS::Search

	def initialize(album, artist, opts={})
		default_opts = {
			# Where your album art is stored
			:art_folder => '~/.albumart/',
			# Location of your Amazon Developer's Key
			:amazon_key_path => '~/.amazonkey',
			# Formats that this script will recognise and try to use
			:art_formats => ['jpg', 'png'],
			# Valid names for art files
			:possible_filenames => [album.to_s+' - '+artist.to_s, album.to_s]
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
				filename = filename.gsub(/[\/\\]/, '_')
				@file = "#{art_folder}#{filename}.#{ext}"
				return if File.exists? @file
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

		# Setup query
		query = ItemSearch.new('Music', { 'Title' => album, 'Artist' => artist })
		rgroup = ResponseGroup.new(:Images)
		request = Request.new(@amazon_key)

		# Query Amazon
		begin
			response = request.search(query, rgroup)
		rescue
			@file = nil
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

		# Save the image
		File.open(@file, 'wb') do |f| 
			f << data.body
			f.flush
		end
	end
end
