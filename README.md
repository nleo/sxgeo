# Sxgeo

Порт Sypex Geo 2.1 - PHP класса для определение местоположения по IP-адресу заточенный для России.

Гем содержит в себе бинарный файл БД по городам городов.

Пример использования:

		SxGeo.new.get(ip)['city'].force_encoding('UTF-8')

Еще примеры http://sypexgeo.net/ru/docs/

batch mode пока не работает.
