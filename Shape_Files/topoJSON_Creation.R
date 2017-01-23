########################################################################################
###
### Script to rename and convert shape files to topoJSON
### All Shape files downloaded from
### https://nces.ed.gov/programs/edge/geographicDistrictBoundary.aspx
###
########################################################################################

### Load packages

require(data.table)


### Parameters

current.year <- 2016


### Load Data

state.lookup <- fread("State_Codes.csv", colClasses=rep("character", 3))


### Copy and Unzip files

setwd(paste("Source_Files", current.year, sep="_"))
system("cp Base_Files/*.zip .")
system("unzip SCHOOLDISTRICT_SY1314_TL15.zip")
system("unzip National_Assessment_of_Educational_Progress_20052015.zip")


####################################################################
###
### Minor cleanup of base shape files
###
####################################################################

system("mapshaper snap  schooldistrict_sy1314_tl15.shp -filter \"NAME!='School District Not Defined'\" -o force")
system("mapshaper snap National_Assessment_of_Educational_Progress_20052015.shp -o force")


###################################################################
###
### Create state files
###
###################################################################

system("mapshaper schooldistrict_sy1314_tl15.shp -split STATEFP -o")

state.numbers <- sort(strhead(sapply(strsplit(list.files(pattern="shp$"), "-"), '[', 2), 2))

for (i in state.numbers) {
	print(paste("Starting:", state.abbreviation <- state.lookup[CODE==i]$STATE_ABBREVIATION))
	system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 -p name=NAME -p state=STATEFP -o TEMP.json", paste0("schooldistrict_sy1314_tl15-", i, ".shp")))
	system(paste("topojson -s 7e-7 --q0=0 --q1=1e6 -o TEMP_NO_PROPERTIES.json", paste0("schooldistrict_sy1314_tl15-", i, ".shp")))
	system(paste("sed -i -e 's/", paste0("schooldistrict_sy1314_tl15-", i), "/districts/g' ", "TEMP.json", sep=""))
	system("sed -i -e 's/\\\\u0000//g' TEMP.json")
	system(paste("sed -i -e 's/", paste0("schooldistrict_sy1314_tl15-", i), "/districts/g' ", "TEMP_NO_PROPERTIES.json", sep=""))
	system("sed -i -e 's/\\\\u0000//g' TEMP_NO_PROPERTIES.json")
	file.rename("TEMP.json", paste0(state.abbreviation, "_Districts.topojson"))
	file.rename("TEMP_NO_PROPERTIES.json", paste0(state.lookup[CODE==i]$STATE_ABBREVIATION, "_Districts_NO_PROPERTIES.topojson"))
}


###################################################################
###
### Create national file
###
###################################################################

system("node --max_old_space_size=8192 /usr/local/share/npm/bin/topojson -s 7e-7 --q0=0 --q1=1e6 -p name=STATE_NAME -p state=STATE_FIPS -o STATE.json National_Assessment_of_Educational_Progress_20052015.shp")
system("node --max_old_space_size=8192 /usr/local/share/npm/bin/topojson -s 7e-7 --q0=0 --q1=1e6 -o STATE_NO_PROPERTIES.json National_Assessment_of_Educational_Progress_20052015.shp")
system("sed -i -e 's/National_Assessment_of_Educational_Progress_20052015/states/g' STATE.json")
system("sed -i -e 's/\\\\u0000//g' STATE.json")
system("sed -i -e 's/National_Assessment_of_Educational_Progress_20052015/states/g' STATE_NO_PROPERTIES.json")
system("sed -i -e 's/\\\\u0000//g' STATE_NO_PROPERTIES.json")
file.rename("STATE.json", "USA_States.topojson")
file.rename("STATE_NO_PROPERTIES.json", "USA_States_NO_PROPERTIES.topojson")

system("node --max_old_space_size=8192 /usr/local/share/npm/bin/topojson -s 7e-7 --q0=0 --q1=1e6 -p name=NAME -p state=STATEFP -o TEMP.json schooldistrict_sy1314_tl15.shp")
system("node --max_old_space_size=8192 /usr/local/share/npm/bin/topojson -s 7e-7 --q0=0 --q1=1e6 -o TEMP_NO_PROPERTIES.json schooldistrict_sy1314_tl15.shp")
system("sed -i -e 's/schooldistrict_sy1314_tl15/districts/g' TEMP.json")
system("sed -i -e 's/\\\\u0000//g' TEMP.json")
system("sed -i -e 's/schooldistrict_sy1314_tl15/districts/g' TEMP_NO_PROPERTIES.json")
system("sed -i -e 's/\\\\u0000//g' TEMP_NO_PROPERTIES.json")
file.rename("TEMP.json", "USA_Districts.topojson")
file.rename("TEMP_NO_PROPERTIES.json", "USA_Districts_NO_PROPERTIES.topojson")

system("mapshaper -i USA_Districts.topojson USA_States_NO_PROPERTIES.topojson combine-files -o USA_Districts_States.topojson format=topojson")
system("mapshaper -i USA_Districts_NO_PROPERTIES.topojson USA_States_NO_PROPERTIES.topojson combine-files -o USA_Districts_States_NO_PROPERTIES.topojson format=topojson")


### Move topojson files

dir.create(paste("../Topojson_", current.year, sep=""), showWarnings=FALSE)
system(paste("mv *.topojson", paste("../Topojson_", current.year, sep="")))
system("rm *.*")

### Reset working directory

setwd("..")
