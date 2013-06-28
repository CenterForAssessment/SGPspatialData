#####################################################################
###
### Script to rename and convert shape files to geoJSON and topoJSON
###
#####################################################################

### Function to get abbreviation


### Copy and Unzip files

system("cp Tiger_Line_Zip_Files/*.zip .")

tmp.unique.indices <- unique(sapply(strsplit(list.files(pattern="zip"), "_"), '[', 3))

for (i in list.files(pattern="zip")) {
	system(paste("unzip", i))
}


### Get abbreviation and rename

for (i in tmp.unique.indices) {
        tmp <- readLines(paste("tl_2012_", i, "_unsd.shp.xml", sep=""))
        tmp.abb <- gsub("\t|placekey|<|>|/", "", tmp[grep("placekey", tmp)][5])
	tmp.new.name <- paste(tmp.abb, "Districts", sep="_")

        for (j in list.files(pattern=paste("tl_2012_", i, sep=""))) {
                tmp.suffix <- sapply(lapply(strsplit(j, "[.]"), '[', -1), paste, collapse=".")
                file.rename(j, paste(tmp.new.name, tmp.suffix, sep="."))
        }

	if (i==tmp.unique.indices[1]) {
		system(paste("ogr2ogr USA_Districts.shp", paste(tmp.new.name, "shp", sep="."))) 
	}

	system(paste("topojson -o",  paste(tmp.new.name, "topojson", sep="."), paste(tmp.new.name, "shp", sep=".")))
	system(paste("ogr2ogr -update -append USA_Districts.shp", paste(tmp.new.name, "shp", sep="."), "-nln USA_Districts"))
}

system(paste("topojson -o USA_Districts.topojson USA_Districts.shp"))



### Remove extraneous files

tmp.file.suffixes <- c("dbf", "prj", "shp", "shp.xml", "prj", "shx")

for (i in tmp.file.suffixes) {
	system(paste("rm", paste("*", i, sep=".")))
}


### Add together state data


