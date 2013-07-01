#####################################################################
###
### Script to rename and convert shape files to geoJSON and topoJSON
###
#####################################################################

### Function to get abbreviation


### Copy and Unzip files

setwd("Source_Files")
system("cp Tiger_Line_Zip_Files/*.zip .")

tmp.unique.indices <- unique(sapply(strsplit(list.files(pattern="zip"), "_"), '[', 3))

for (i in list.files(pattern="zip")) {
	system(paste("unzip", i))
}


### Start merging .shp files

for (i in tmp.unique.indices) {
        tmp <- readLines(paste("tl_2012_", i, "_unsd.shp.xml", sep=""))
        tmp.abb <- gsub("\t|placekey|<|>|/", "", tmp[grep("placekey", tmp)][5])
	tmp.new.name <- paste(tmp.abb, "Districts", sep="_")
	tmp.shp.file.names <- grep(".xml", grep(".shp", list.files(pattern=paste("tl_2012_", i, sep="")), value=TRUE), value=TRUE, invert=TRUE)
	if (i==tmp.unique.indices[1]) {
		system(paste("ogr2ogr USA_Districts.shp", tail(tmp.shp.file.names, 1))) 
	}

	if (length(tmp.shp.file.names) > 1) {
		system(paste("ogr2ogr", paste(tmp.abb, "Districts.shp", sep="_"), tail(tmp.shp.file.names, 1))) 
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

system(paste("topojson -q 1e5 -s 7e-7 -p District=NAME -p District -o USA_Districts_100_percent.topojson USA_Districts.shp"))
system(paste("topojson -q 1e5 -s 7e-7 -p District=NAME -p District -o USA_Districts_50_percent.topojson --simplify-proportion .50 USA_Districts.shp"))
system(paste("topojson -q 1e5 -s 7e-7 -p District=NAME -p District -o USA_Districts_25_percent.topojson --simplify-proportion .25 USA_Districts.shp"))
system(paste("topojson -q 1e5 -s 7e-7 -p District=NAME -p District -o USA_Districts_20_percent.topojson USA_Districts.shp"))


### Move topojson files

system(paste("mv *.topojson .."))


### Reset working directory

setwd("..")
