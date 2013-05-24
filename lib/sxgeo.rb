require "sxgeo/version"

class SxGeo

	SXGEO_FILE = 0
	SXGEO_MEMORY = 1
	SXGEO_BATCH = 2

	def initialize (db_file = File.dirname(__FILE__) + "/sxgeo/SxGeoCity.dat", type = SXGEO_FILE)
		@cc2iso = [
			'', 'AP', 'EU', 'AD', 'AE', 'AF', 'AG', 'AI', 'AL', 'AM', 'AN', 'AO', 'AQ',
			'AR', 'AS', 'AT', 'AU', 'AW', 'AZ', 'BA', 'BB', 'BD', 'BE', 'BF', 'BG', 'BH',
			'BI', 'BJ', 'BM', 'BN', 'BO', 'BR', 'BS', 'BT', 'BV', 'BW', 'BY', 'BZ', 'CA',
			'CC', 'CD', 'CF', 'CG', 'CH', 'CI', 'CK', 'CL', 'CM', 'CN', 'CO', 'CR', 'CU',
			'CV', 'CX', 'CY', 'CZ', 'DE', 'DJ', 'DK', 'DM', 'DO', 'DZ', 'EC', 'EE', 'EG',
			'EH', 'ER', 'ES', 'ET', 'FI', 'FJ', 'FK', 'FM', 'FO', 'FR', 'FX', 'GA', 'GB',
			'GD', 'GE', 'GF', 'GH', 'GI', 'GL', 'GM', 'GN', 'GP', 'GQ', 'GR', 'GS', 'GT',
			'GU', 'GW', 'GY', 'HK', 'HM', 'HN', 'HR', 'HT', 'HU', 'ID', 'IE', 'IL', 'IN',
			'IO', 'IQ', 'IR', 'IS', 'IT', 'JM', 'JO', 'JP', 'KE', 'KG', 'KH', 'KI', 'KM',
			'KN', 'KP', 'KR', 'KW', 'KY', 'KZ', 'LA', 'LB', 'LC', 'LI', 'LK', 'LR', 'LS',
			'LT', 'LU', 'LV', 'LY', 'MA', 'MC', 'MD', 'MG', 'MH', 'MK', 'ML', 'MM', 'MN',
			'MO', 'MP', 'MQ', 'MR', 'MS', 'MT', 'MU', 'MV', 'MW', 'MX', 'MY', 'MZ', 'NA',
			'NC', 'NE', 'NF', 'NG', 'NI', 'NL', 'NO', 'NP', 'NR', 'NU', 'NZ', 'OM', 'PA',
			'PE', 'PF', 'PG', 'PH', 'PK', 'PL', 'PM', 'PN', 'PR', 'PS', 'PT', 'PW', 'PY',
			'QA', 'RE', 'RO', 'RU', 'RW', 'SA', 'SB', 'SC', 'SD', 'SE', 'SG', 'SH', 'SI',
			'SJ', 'SK', 'SL', 'SM', 'SN', 'SO', 'SR', 'ST', 'SV', 'SY', 'SZ', 'TC', 'TD',
			'TF', 'TG', 'TH', 'TJ', 'TK', 'TM', 'TN', 'TO', 'TL', 'TR', 'TT', 'TV', 'TW',
			'TZ', 'UA', 'UG', 'UM', 'US', 'UY', 'UZ', 'VA', 'VC', 'VE', 'VG', 'VI', 'VN',
			'VU', 'WF', 'WS', 'YE', 'YT', 'RS', 'ZA', 'ZM', 'ME', 'ZW', 'A1', 'A2', 'O1',
			'AX', 'GG', 'IM', 'JE', 'BL', 'MF'
		]

		@batch_mode  = false
		@memory_mode = false
		@debug_mode  = false

		@fh = File.open(db_file, 'rb')
		# Сначала убеждаемся, что есть файл базы данных
		header = @fh.read 32
		raise "Can't open #{db_file}" if header[0, 3] != 'SxG'
		# 'Cver/Ntime/Ctype/Ccharset/Cb_idx_len/nm_idx_len/nrange/Ndb_items/Cid_len/nmax_region/nmax_city/Nregion_size/Ncity_size'
		@ver, @time, @type, @charset, @b_idx_len, @m_idx_len, @range, @db_items, @id_len,
		  @max_region, @max_city, @region_size, @city_size = header[3, 32].unpack('CNCCCnnNCnnNN')
		raise "Wrong file format #{db_file}" if @b_idx_len * @m_idx_len * @range * @db_items * @time * @id_len == 0
		@b_idx_str = @fh.read @b_idx_len * 4
		@m_idx_str = @fh.read @m_idx_len * 4
		@block_len   = 3 + @id_len;
		@batch_mode  = type & SXGEO_BATCH
		@memory_mode = type & SXGEO_MEMORY
		@db_begin = @fh.tell
		if (@batch_mode)
			@b_idx_arr = @b_idx_str.unpack("N*")
			@m_idx_arr = @m_idx_str.scan(/.{1,4}/)
		end
		if (@memory_mode)
			@db = @fh.read @db_items * @block_len
			@regions_db = @fh.read @region_size
			@cities_db  = @fh.read @city_size
		end
		@regions_begin = @db_begin + @db_items * @block_len;
		@cities_begin = @regions_begin + @region_size
	end

	def search_idx(ipn, min, max)
		puts "search_idx ===> #{ipn}, #{min}, #{max}, batch_mode: #{@batch_mode}" if @debug_mode
		if @batch_mode != 0
			while (max - min) > 8
				offset = (min + max) >> 1
				if ipn > @m_idx_arr[offset]
					min = offset
				else
					max = offset
				end
			end
			while ipn > @m_idx_arr[min] && min < max
				min+=1
			end
		else
			while (max - min) > 8
				offset = (min + max) >> 1
				if ipn > @m_idx_str[offset*4, offset*4 + 4]
					min = offset
				else
					max = offset
				end
			end
			puts "max: #{max} min: #{min}" if @debug_mode
			while (ipn > @m_idx_str[min*4, min*4+4]) && (min < max)
				min+=1
			end
		end
		return min
	end

	def search_db(str, ipn, min, max)
		if (max - min) > 0
			ipn = ipn[1, ipn.length]
			while (max - min) > 8
				offset = (min + max) >> 1;
				if ipn > str[offset * @block_len, 3]
					min = offset
				else
					max = offset
				end
			end
			while (ipn >= str[min * @block_len, 3]) && (min < max)
				min+=1
			end
		else
			return str[min * @block_len + 3 , 3].unpack('H*').first.hex
		end
		return str[min * @block_len - @id_len, @id_len].unpack('H*').first.hex
	end

	def get_num(ip)
		ip1n = ip.split('.').first.to_i  #(int)ip; // Первый байт
		# binding.pry
		ipn = ip2long(ip)
		puts "ipn: #{ipn}" if @debug_mode
		# TODO
		# if ip1n == 0 || ip1n == 10 || ip1n == 127 || ip1n >= @b_idx_len || false === (ipn = ip2long(ip)) # TODO
		# 	return false
		# end
		ipn = [ipn].pack 'N'
		@ip1c = ip1n.chr
		# Находим блок данных индексе первых байт
		blocks = {}
		if @batch_mode
			blocks = {'min' => @b_idx_arr[ip1n.to_i-1], 'max' => @b_idx_arr[ip1n.to_i]}
		else
			blocks['min'], blocks['max'] = @b_idx_str[(ip1n - 1) * 4, (ip1n - 1) * 4+8].unpack 'NN'
		end
		puts blocks if @debug_mode
		# Ищем блок в основном индексе
		part = search_idx(ipn, (blocks['min'] / @range).floor, (blocks['max'] / @range).floor-1)
		puts "PART #{part}" if @debug_mode
		# Нашли номер блока в котором нужно искать IP, теперь находим нужный блок в БД
		min = part > 0 ? part * @range : 0
		max = part > @m_idx_len ? @db_items : (part+1) * @range
		# Нужно проверить чтобы блок не выходил за пределы блока первого байта
		min = blocks['min'] if min < blocks['min']
		max = blocks['max'] if max > blocks['max']
		len = max - min
		# Находим нужный диапазон в БД
		if @memory_mode
			puts "#{ipn}, #{min}, #{max}" if @debug_mode
			return search_db(@db, ipn, min, max)
		else
			@fh.pos = @db_begin + min * @block_len
			return search_db(@fh.read(len * @block_len), ipn, 0, len-1)
		end
	end

	def ip2long(ip)
	  long = 0
	  ip.split('.').each_with_index do |b, i|
	    long += b.to_i << ( 8*(3-i) )
	  end
	  long
	end

	def parseCity(seek)
		if @memory_mode
			raw = @cities_db[seek, @max_city]
		else
			@fh.pos = @cities_begin + seek
			raw = @fh.read @max_city
		end
		@city = {}
		@city['regid'], @city['cc'],
			@city['2fips'], @city['lat'], @city['lon'] = raw.unpack 'NCaNN'
		@city['country']  = @cc2iso[@city['cc']];
		@city['lat'] /= 1000000;
		@city['lon'] /= 1000000;
		@city['city'] = raw[15,raw.length].split("\0").first
		return @city;
	end

	def parseRegion(region_seek)
		tz = [ '',  'Africa/Abidjan', 'Africa/Accra', 'Africa/Addis_Ababa', 'Africa/Algiers', 'Africa/Bamako', 'Africa/Banjul',
			'Africa/Blantyre', 'Africa/Brazzaville', 'Africa/Bujumbura', 'Africa/Cairo', 'Africa/Casablanca', 'Africa/Ceuta',
			'Africa/Conakry', 'Africa/Dakar', 'Africa/Dar_es_Salaam', 'Africa/Douala', 'Africa/Freetown', 'Africa/Gaborone',
			'Africa/Harare', 'Africa/Johannesburg', 'Africa/Kampala', 'Africa/Khartoum', 'Africa/Kigali', 'Africa/Kinshasa',
			'Africa/Lagos', 'Africa/Libreville', 'Africa/Luanda', 'Africa/Lubumbashi', 'Africa/Lusaka', 'Africa/Malabo',
			'Africa/Maputo', 'Africa/Maseru', 'Africa/Mbabane', 'Africa/Mogadishu', 'Africa/Monrovia', 'Africa/Nairobi',
			'Africa/Ndjamena', 'Africa/Niamey', 'Africa/Nouakchott', 'Africa/Ouagadougou', 'Africa/Porto-Novo', 'Africa/Tripoli',
			'Africa/Tunis', 'Africa/Windhoek', 'America/Anchorage', 'America/Anguilla', 'America/Antigua', 'America/Araguaina',
			'America/Argentina/Buenos_Aires', 'America/Argentina/Catamarca', 'America/Argentina/Cordoba', 'America/Argentina/Jujuy',
			'America/Argentina/La_Rioja', 'America/Argentina/Mendoza', 'America/Argentina/Rio_Gallegos', 'America/Argentina/Salta',
			'America/Argentina/San_Juan', 'America/Argentina/San_Luis', 'America/Argentina/Tucuman', 'America/Argentina/Ushuaia',
			'America/Asuncion', 'America/Bahia', 'America/Bahia_Banderas', 'America/Barbados', 'America/Belem', 'America/Belize',
			'America/Boa_Vista', 'America/Bogota', 'America/Campo_Grande', 'America/Cancun', 'America/Caracas', 'America/Chicago',
			'America/Chihuahua', 'America/Costa_Rica', 'America/Cuiaba', 'America/Denver', 'America/Dominica', 'America/Edmonton',
			'America/El_Salvador', 'America/Fortaleza', 'America/Godthab', 'America/Grenada', 'America/Guatemala', 'America/Guayaquil',
			'America/Guyana', 'America/Halifax', 'America/Havana', 'America/Hermosillo', 'America/Indianapolis', 'America/Iqaluit',
			'America/Jamaica', 'America/La_Paz', 'America/Lima', 'America/Los_Angeles', 'America/Maceio', 'America/Managua',
			'America/Manaus', 'America/Matamoros', 'America/Mazatlan', 'America/Merida', 'America/Mexico_City', 'America/Moncton',
			'America/Monterrey', 'America/Montevideo', 'America/Montreal', 'America/Nassau', 'America/New_York', 'America/Ojinaga',
			'America/Panama', 'America/Paramaribo', 'America/Phoenix', 'America/Port_of_Spain', 'America/Port-au-Prince',
			'America/Porto_Velho', 'America/Recife', 'America/Regina', 'America/Rio_Branco', 'America/Santo_Domingo',
			'America/Sao_Paulo', 'America/St_Johns', 'America/St_Kitts', 'America/St_Lucia', 'America/St_Vincent',
			'America/Tegucigalpa', 'America/Thule', 'America/Tijuana', 'America/Vancouver', 'America/Whitehorse', 'America/Winnipeg',
			'America/Yellowknife', 'Asia/Aden', 'Asia/Almaty', 'Asia/Amman', 'Asia/Anadyr', 'Asia/Aqtau', 'Asia/Aqtobe', 'Asia/Baghdad',
			'Asia/Bahrain', 'Asia/Baku', 'Asia/Bangkok', 'Asia/Beirut', 'Asia/Bishkek', 'Asia/Choibalsan', 'Asia/Chongqing',
			'Asia/Colombo', 'Asia/Damascus', 'Asia/Dhaka', 'Asia/Dubai', 'Asia/Dushanbe', 'Asia/Harbin', 'Asia/Ho_Chi_Minh',
			'Asia/Hong_Kong', 'Asia/Hovd', 'Asia/Irkutsk', 'Asia/Jakarta', 'Asia/Jayapura', 'Asia/Jerusalem', 'Asia/Kabul',
			'Asia/Kamchatka', 'Asia/Karachi', 'Asia/Kashgar', 'Asia/Kolkata', 'Asia/Krasnoyarsk', 'Asia/Kuala_Lumpur', 'Asia/Kuching',
			'Asia/Kuwait', 'Asia/Macau', 'Asia/Magadan', 'Asia/Makassar', 'Asia/Manila', 'Asia/Muscat', 'Asia/Nicosia', 'Asia/Novokuznetsk',
			'Asia/Novosibirsk', 'Asia/Omsk', 'Asia/Oral', 'Asia/Phnom_Penh', 'Asia/Pontianak', 'Asia/Qatar', 'Asia/Qyzylorda', 'Asia/Riyadh',
			'Asia/Sakhalin', 'Asia/Seoul', 'Asia/Shanghai', 'Asia/Singapore', 'Asia/Taipei', 'Asia/Tashkent', 'Asia/Tbilisi', 'Asia/Tehran',
			'Asia/Thimphu', 'Asia/Tokyo', 'Asia/Ulaanbaatar', 'Asia/Urumqi', 'Asia/Vientiane', 'Asia/Vladivostok', 'Asia/Yakutsk',
			'Asia/Yekaterinburg', 'Asia/Yerevan', 'Atlantic/Azores', 'Atlantic/Bermuda', 'Atlantic/Canary', 'Atlantic/Cape_Verde',
			'Atlantic/Madeira', 'Atlantic/Reykjavik', 'Australia/Adelaide', 'Australia/Brisbane', 'Australia/Darwin', 'Australia/Hobart',
			'Australia/Melbourne', 'Australia/Perth', 'Australia/Sydney', 'Chile/Santiago', 'Europe/Amsterdam', 'Europe/Andorra',
			'Europe/Athens', 'Europe/Belgrade', 'Europe/Berlin', 'Europe/Bratislava', 'Europe/Brussels', 'Europe/Bucharest', 'Europe/Budapest',
			'Europe/Chisinau', 'Europe/Copenhagen', 'Europe/Dublin', 'Europe/Gibraltar', 'Europe/Helsinki', 'Europe/Istanbul',
			'Europe/Kaliningrad', 'Europe/Kiev', 'Europe/Lisbon', 'Europe/Ljubljana', 'Europe/London', 'Europe/Luxembourg', 'Europe/Madrid',
			'Europe/Malta', 'Europe/Mariehamn', 'Europe/Minsk', 'Europe/Monaco', 'Europe/Moscow', 'Europe/Oslo', 'Europe/Paris',
			'Europe/Prague', 'Europe/Riga', 'Europe/Rome', 'Europe/Samara', 'Europe/San_Marino', 'Europe/Sarajevo', 'Europe/Simferopol',
			'Europe/Skopje', 'Europe/Sofia', 'Europe/Stockholm', 'Europe/Tallinn', 'Europe/Tirane', 'Europe/Uzhgorod', 'Europe/Vaduz',
			'Europe/Vatican', 'Europe/Vienna', 'Europe/Vilnius', 'Europe/Volgograd', 'Europe/Warsaw', 'Europe/Yekaterinburg', 'Europe/Zagreb',
			'Europe/Zaporozhye', 'Europe/Zurich', 'Indian/Antananarivo', 'Indian/Comoro', 'Indian/Mahe', 'Indian/Maldives', 'Indian/Mauritius',
			'Pacific/Auckland', 'Pacific/Chatham', 'Pacific/Efate', 'Pacific/Fiji', 'Pacific/Galapagos', 'Pacific/Guadalcanal', 'Pacific/Honolulu',
			'Pacific/Port_Moresby' ]
		if region_seek > 0
			if @memory_mode
				region = @regions_db[region_seek, @max_region].split "\0"
			else
				@fh.pos = @info['regions_begin'] + region_seek
				region = @fh.read(@max_region).split "\0"
			end
			@city['region_name'] = region[0]
			@city['timezone'] = tz[region[1]]
		else
			@city['region_name'] = ''
			@city['timezone'] = ''
		end
	end

	def get(ip)
		@max_city ? getCity(ip) : getCountry(ip)
	end

	def getCountry(ip)
		@cc2iso[get_num(ip)]
	end

	def getCountryId(ip)
		get_num(ip)
	end

	def getCity(ip)
		seek = get_num(ip)
		seek > 0 ? parseCity(seek) : false
	end

	def getCityFull(ip)
		seek = get_num(ip)
		if seek > 0
			parseCity(seek)
			parseRegion(@city['regid'])
			@city
		else
			false
		end
	end

end
