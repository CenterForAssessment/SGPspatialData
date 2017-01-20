########################################################################################
###
### Script to rename and convert shape files to topoJSON
### All Shape files downloaded from https://www.census.gov/did/www/schooldistricts/
###
########################################################################################

### Load packages

require(data.table)


### Parameters

current.year <- 2016


### Misc functions

"%w/o%" <- function(x, y) x[!x %in% y]


### Load Data

state.lookup <- fread("State_Codes.csv", colClasses=rep("character", 3))


### Copy and Unzip files

setwd(paste("Source_Files", current.year, sep="_"))
system("cp Base_Files/*.zip .")
system("unzip SCHOOLDISTRICT_SY1314_TL15.zip")


###################################################################
###
### Create state files
###
###################################################################

system("mapshaper schooldistrict_sy1314_tl15.shp -split STATEFP -o")

state.numbers <- sort(strhead(sapply(strsplit(list.files(pattern="shp$"), "-"), '[', 2), 2))

for (i in state.numbers) {
	print(paste("Starting:", state.abbreviation <- state.lookup[CODE==i]$STATE_ABBREVIATION))
	system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 -p name=NAME -o TEMP.json", paste0("schooldistrict_sy1314_tl15-", i, ".shp")))
	system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 -o TEMP_NO_PROPERTIES.json", paste0("schooldistrict_sy1314_tl15-", i, ".shp")))
	system(paste("sed -i -e 's/", paste0("schooldistrict_sy1314_tl15-", i), "/districts/g' ", "TEMP.json", sep=""))
	system(paste("sed -i -e 's/", paste0("schooldistrict_sy1314_tl15-", i), "/districts/g' ", "TEMP_NO_PROPERTIES.json", sep=""))
	file.rename("TEMP.json", paste0(state.abbreviation, "_Districts.topojson"))
	file.rename("TEMP_NO_PROPERTIES.json", paste0(state.lookup[CODE==i]$STATE_ABBREVIATION, "_Districts_NO_PROPERTIES.topojson"))
}


###################################################################
###
### Create national file
###
###################################################################

system("node --max_old_space_size=8192 /usr/local/share/npm/bin/topojson -s 7e-7 --q0=0 --q1=1e6 -p name=NAME -o TEMP.json schooldistrict_sy1314_tl15.shp")
system("node --max_old_space_size=8192 /usr/local/share/npm/bin/topojson -s 7e-7 --q0=0 --q1=1e6 -o TEMP_NO_PROPERTIES.json schooldistrict_sy1314_tl15.shp")
system("sed -i -e 's/USA_Districts/districts/g' TEMP.json")
system("sed -i -e 's/USA_Districts/districts/g' TEMP_NO_PROPERTIES.json")
file.rename("TEMP.json", "USA_Districts.topojson")
file.rename("TEMP_NO_PROPERTIES.json", "USA_Districts_NO_PROPERTIES.topojson")


### Move topojson files

dir.create(paste("../Topojson_", current.year, sep=""), showWarnings=FALSE)
system(paste("mv *.topojson", paste("../Topojson_", current.year, sep="")))


### Reset working directory

setwd("..")






for (i in tmp.unique.indices) {
    tmp <- suppressWarnings(readLines(paste("tl_", current.year, "_", i, "_unsd.shp.xml", sep="")))
	tmp.abb <- tmp[grep("placekey", tmp)+1][9]
	tmp.new.name <- paste(tmp.abb, "Districts", sep="_")
	tmp.shp.file.names <- grep(".xml", grep(".shp", list.files(pattern=paste("tl_", current.year, "_", i, sep="")), value=TRUE), value=TRUE, invert=TRUE)
	if (i==tmp.unique.indices[1]) {
		system(paste("ogr2ogr -f 'ESRI Shapefile' USA_Districts.shp", tail(tmp.shp.file.names, 1)))
	}

	if (length(tmp.shp.file.names) > 1) {
		print(paste("STARTING", tmp.abb))
		system(paste("ogr2ogr -f 'ESRI Shapefile'", paste(tmp.abb, "Districts.shp", sep="_"), tail(tmp.shp.file.names, 1)))
		for (j in tmp.shp.file.names) {
			system(paste("ogr2ogr -update -append", paste(tmp.new.name, "shp", sep="."), j, "-nln", paste(tmp.abb, "Districts", sep="_")))
			if (tmp.abb %in% state.abb) {
				system(paste("ogr2ogr -update -append USA_Districts.shp", j, "-nln USA_Districts"))
			}
		}
		system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 -p name=NAME -o TEMP.json", paste(tmp.new.name, "shp", sep=".")))
		system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 --ignore-shapefile-properties true -o TEMP_NO_PROPERTIES.json", paste(tmp.new.name, "shp", sep=".")))
		system(paste("sed -i -e 's/", tmp.new.name, "/districts/g' ", "TEMP.json", sep=""))
		system(paste("sed -i -e 's/", tmp.new.name, "/districts/g' ", "TEMP_NO_PROPERTIES.json", sep=""))
		if (tmp.abb %in% state.abb) {
			system(paste("topomerge state=districts < TEMP.json >", paste(tmp.new.name, ".topojson", sep="")))
			system(paste("topomerge state=districts < TEMP_NO_PROPERTIES.json >", paste(tmp.new.name, "_NO_PROPERTIES.topojson", sep="")))
		} else {
			file.rename("TEMP.json", paste(tmp.new.name, ".topojson", sep=""))
			file.rename("TEMP_NO_PROPERTIES.json", paste(tmp.new.name, "_NO_PROPERTIES.topojson", sep=""))
		}
	} else {
		print(paste("STARTING", tmp.abb))
		system(paste("ogr2ogr -f 'ESRI Shapefile'", paste(tmp.abb, "Districts.shp", sep="_"), tail(tmp.shp.file.names, 1)))
		if (tmp.abb %in% setdiff(state.abb, c("AK", "HI"))) {
			system(paste("ogr2ogr -update -append USA_Districts.shp", tmp.shp.file.names, "-nln USA_Districts"))
		}
		system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 -p name=NAME -o TEMP.json",  tmp.shp.file.names))
		system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 --ignore-shapefile-properties true -o TEMP_NO_PROPERTIES.json",  tmp.shp.file.names))
		system(paste("sed -i -e 's/", sub(".shp", "", tmp.shp.file.names), "/districts/g' ", "TEMP.json", sep=""))
		system(paste("sed -i -e 's/", sub(".shp", "", tmp.shp.file.names), "/districts/g' ", "TEMP_NO_PROPERTIES.json", sep=""))
		if (tmp.abb %in% state.abb) {
			system(paste("topomerge state=districts < TEMP.json >", paste(tmp.new.name, ".topojson", sep="")))
			system(paste("topomerge state=districts < TEMP_NO_PROPERTIES.json >", paste(tmp.new.name, "_NO_PROPERTIES.topojson", sep="")))
		} else {
			file.rename("TEMP.json", paste(tmp.new.name, ".topojson", sep=""))
			file.rename("TEMP_NO_PROPERTIES.json", paste(tmp.new.name, "_NO_PROPERTIES.topojson", sep=""))
		}
	}
}

###################################################################
###
### Create state shapefile from national file and Create
### topoJSON file for nation
###
###################################################################

system("mapshaper snap USA_Districts.shp -o USA_Districts_FIXED.shp")
system("mapshaper USA_Districts_FIXED.shp -dissolve STATEFP -o USA_States.shp")
#system("ogr2ogr -update -append USA_Districts_FIXED.shp USA_States.shp")
#system("node --max_old_space_size=8192 /usr/local/share/npm/bin/topojson -s 7e-7 --q0=0 --q1=1e6 -p name=NAME -o TEMP.json USA_Districts_FIXED.shp")




#system(paste("node --max_old_space_size=8192 /usr/local/share/npm/bin/topojson -s 7e-7 --q0=0 --q1=1e6 --ignore-shapefile-properties true -o TEMP_NO_PROPERTIES.json USA_Districts.shp"))
#system("sed -i -e 's/USA_Districts/districts/g' TEMP.json")
#system("sed -i -e 's/USA_Districts/districts/g' TEMP_NO_PROPERTIES.json")
#system("topomerge state=districts < TEMP.json > USA_Districts.topojson")
#system("topomerge state=districts < TEMP_NO_PROPERTIES.json > USA_Districts_NO_PROPERTIES.topojson")


### Move topojson files

#dir.create(paste("../Topojson_", current.year, sep=""), showWarnings=FALSE)
#system(paste("mv *.topojson", paste("../Topojson_", current.year, sep="")))


### Reset working directory

#setwd("..")
