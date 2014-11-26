## Google font to local CSS file ##

Since Google generates diffrent font response according to user agent it makes it very annoying to download a font to your local server for many different reasons.

This script it makes it very easy to download all possible fonts from Google by adjusting headers for all relevant types and font weights.

Tested on Ruby 1.9.3

## Example cli ##

	ruby google_fonts_dl.rb -f Montserrat:400,700 -f Raleway:400,500,600


## Dir structure ##

	`-- tmp_fonts
    |-- fonts
    |   |-- montserrat
    |   |   |-- montserrat_400.eot
    |   |   |-- montserrat_400.ttf
    |   |   |-- montserrat_400.woff
    |   |   |-- montserrat_400.woff2
    |   |   |-- montserrat_700.ttf
    |   |   |-- montserrat_700.woff
    |   |   `-- montserrat_700.woff2
    |   `-- raleway
    |       |-- raleway_400.eot
    |       |-- raleway_400.ttf
    |       |-- raleway_400.woff
    |       |-- raleway_400.woff2
    |       |-- raleway_500.ttf
    |       |-- raleway_500.woff
    |       |-- raleway_500.woff2
    |       |-- raleway_600.ttf
    |       |-- raleway_600.woff
    |       `-- raleway_600.woff2
    `-- fonts.css
    
    4 directories, 18 files
	

Enjoy
