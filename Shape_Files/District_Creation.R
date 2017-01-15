########################################################################################
###
### Script to rename and convert shape files to topoJSON
### All Shape files downloaded from https://www.census.gov/did/www/schooldistricts/
###
########################################################################################

### Parameters

current.year <- 2016

### Misc functions

"%w/o%" <- function(x, y) x[!x %in% y]

### Copy and Unzip files

setwd(paste("Source_Files", current.year, sep="_"))
system("cp Tiger_Line_Zip_Files/*.zip .")

tmp.unique.indices <- unique(sapply(strsplit(list.files(pattern="zip"), "_"), '[', 3)) %w/o% "us"

for (i in list.files(pattern="zip")) {
	system(paste("unzip", i))
}


### Start merging .shp files

for (i in tmp.unique.indices) {
        tmp <- suppressWarnings(readLines(paste("tl_", current.year, "_", i, "_unsd.shp.xml", sep="")))
		tmp.abb <- tmp[grep("placekey", tmp)+1][9]
	tmp.new.name <- paste(tmp.abb, "Districts", sep="_")
	tmp.shp.file.names <- grep(".xml", grep(".shp", list.files(pattern=paste("tl_", current.year, "_", i, sep="")), value=TRUE), value=TRUE, invert=TRUE)
	if (i==tmp.unique.indices[1]) {
		system(paste("ogr2ogr -f 'ESRI Shapefile' USA_Districts.shp tl_", current.year, "_us_state.shp", sep=""))
		system(paste("ogr2ogr -f 'ESRI Shapefile' USA_Districts.shp", tail(tmp.shp.file.names, 1)))
	}

	if (length(tmp.shp.file.names) > 1) {
		system(paste("ogr2ogr -f 'ESRI Shapefile'", paste(tmp.abb, "Districts.shp", sep="_"), tail(tmp.shp.file.names, 1)))
		for (j in tmp.shp.file.names) {
			system(paste("ogr2ogr -update -append", paste(tmp.new.name, "shp", sep="."), j, "-nln", paste(tmp.abb, "Districts", sep="_")))
			if (tmp.abb %in% state.abb) {
				system(paste("ogr2ogr -update -append USA_Districts.shp", j, "-nln USA_Districts"))
			}
		}
		system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 --bbox -p District=NAME -o TEMP.json", paste(tmp.new.name, "shp", sep=".")))
		system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 --bbox --ignore-shapefile-properties true -o TEMP_NO_PROPERTIES.json", paste(tmp.new.name, "shp", sep=".")))
		system(paste("sed -i -e 's/", tmp.new.name, "/districts/g' ", "TEMP.json", sep=""))
		system(paste("sed -i -e 's/", tmp.new.name, "/districts/g' ", "TEMP_NO_PROPERTIES.json", sep=""))
#		system(paste("topomerge state=districts < TEMP.json >", paste(tmp.new.name, ".json", sep="")))
#		system(paste("topomerge state=districts < TEMP_NO_PROPERTIES.json >", paste(tmp.new.name, "_NO_PROPERTIES.json", sep="")))
		file.rename("TEMP.json", paste(tmp.new.name, ".json", sep=""))
		file.rename("TEMP_NO_PROPERTIES.json", paste(tmp.new.name, "_NO_PROPERTIES.json", sep=""))
	} else {
		if (tmp.abb %in% setdiff(state.abb, c("AK", "HI"))) {
			system(paste("ogr2ogr -update -append USA_Districts.shp", tmp.shp.file.names, "-nln USA_Districts"))
		}
		system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 --bbox -p district=NAME -o TEMP.json",  tmp.shp.file.names))
		system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 --bbox --ignore-shapefile-properties true -o TEMP_NO_PROPERTIES.json",  tmp.shp.file.names))
		system(paste("sed -i -e 's/", sub(".shp", "", tmp.shp.file.names), "/districts/g' ", "TEMP.json", sep=""))
		system(paste("sed -i -e 's/", sub(".shp", "", tmp.shp.file.names), "/districts/g' ", "TEMP_NO_PROPERTIES.json", sep=""))
#		system(paste("topomerge state=districts < TEMP.json >", paste(tmp.new.name, ".json", sep="")))
#		system(paste("topomerge state=districts < TEMP_NO_PROPERTIES.json >", paste(tmp.new.name, "_NO_PROPERTIES.json", sep="")))
		file.rename("TEMP.json", paste(tmp.new.name, ".json", sep=""))
		file.rename("TEMP_NO_PROPERTIES.json", paste(tmp.new.name, "_NO_PROPERTIES.json", sep=""))
	}
}

system(paste("node --max_old_space_size=8192 /usr/local/share/npm/bin/topojson -s 7e-7 --q0=0 --q1=1e6 --bbox -p District=NAME --id-property=+STATEFP -o USA_Districts.json USA_Districts.shp"))
system(paste("node --max_old_space_size=8192 /usr/local/share/npm/bin/topojson -s 7e-7 --q0=0 --q1=1e6 --bbox --ignore-shapefile-properties true -o USA_Districts_NO_PROPERTIES.json USA_Districts.shp"))
system("sed -i -e 's/USA_Districts/districts/g' USA_Districts.json")
system("sed -i -e 's/USA_Districts/districts/g' USA_Districts_NO_PROPERTIES.json")


### Move topojson files

dir.create(paste("../Topojson_", current.year, sep=""), showWarnings=FALSE)
system(paste("mv *.json", paste("../Topojson_", current.year, sep="")))


### Reset working directory

setwd("..")
