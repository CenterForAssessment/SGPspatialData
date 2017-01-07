#####################################################################
###
### Script to rename and convert shape files to geoJSON and topoJSON
###
#####################################################################

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
		system(paste("topojson -q 1e5 -p District=NAME -p District -o",  paste(tmp.new.name, "_100_Percent.topojson", sep=""), paste(tmp.new.name, "shp", sep=".")))
		system(paste("topojson -q 1e5 -p District=NAME -p District -o",  paste(tmp.new.name, "_25_Percent.topojson", sep=""), "--simplify-proportion .25", paste(tmp.new.name, "shp", sep=".")))
	} else {
		if (tmp.abb %in% state.abb) {
			system(paste("ogr2ogr -update -append USA_Districts.shp", tmp.shp.file.names, "-nln USA_Districts"))
		}
		system(paste("topojson -q 1e5 -p District=NAME -p District -o",  paste(tmp.new.name, "_100_Percent.topojson", sep=""), tmp.shp.file.names))
		system(paste("topojson -q 1e5 -p District=NAME -p District -o",  paste(tmp.new.name, "_25_Percent.topojson", sep=""), "--simplify-proportion .25", tmp.shp.file.names))
	}
}

system(paste("topojson -p District=NAME -p District -o USA_Districts_100_percent.topojson USA_Districts.shp"))
system(paste("topojson -p District=NAME -p District -o USA_Districts_50_percent.topojson --simplify-proportion .50 USA_Districts.shp"))
system(paste("topojson -p District=NAME -p District -o USA_Districts_25_percent.topojson --simplify-proportion .25 USA_Districts.shp"))
system(paste("topojson -p District=NAME -p District -o USA_Districts_20_percent.topojson --simplify-proportion .20 USA_Districts.shp"))


### Move topojson files

system(paste("mv *.topojson .."))


### Reset working directory

setwd("..")
