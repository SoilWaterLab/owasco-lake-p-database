# SQL Example Script to Search Owasco Lake Phosphorus Database
# By Sheila Saia
# Last Updated 11/4/2015
#
#
# ---------------------------------------------------
# Load SQL Library (and Other Important Libraries)
# ---------------------------------------------------
#
library(Cairo) #for plotting
library(sqldf) #R version of sql (i.e. sqlite)
# must have most recent version of R (greater than 3.1.0)
# for more details and examples of how to use the package see
# https://code.google.com/p/sqldf/
#
#
# ---------------------------------------------------
# Set Directory
# ---------------------------------------------------
#
# directory must be set to the folder where database text files are kept
setwd('C://Users//Sheila//Documents//Cornell//CodeRepository//Owasco_Lake_P_ Database//OwascoLakePDatabase//TextFiles')
#
#
# ---------------------------------------------------
# Load Data
# ---------------------------------------------------
#
# load files at once
File_List=read.table('File_List.txt',header=TRUE,sep="\t",fill=TRUE)
for (i in 1:nrow(File_List))
  assign(as.character(File_List[i,1]),read.table(as.character(File_List[i,2]),header=TRUE,sep="\t",fill=TRUE),envir=.GlobalEnv)
#
#
# -----------------------------------------------------------------
# Check Total P (TP) Entries - Quality Control
# -----------------------------------------------------------------
# 
# number of TP entries where SRP>TP
#length(Sample_Data$TPmgL[Sample_Data$TPmgL<Sample_Data$SRPmgL])
#
# location id's of TP entries where SRP>TP
Sample_Data$LocationID[Sample_Data$TPmgL<Sample_Data$SRPmgL]
#
# create new concentration column for corrected data
Sample_Data$TPmgLfix=Sample_Data$TPmgL
#
# set values of new concentration column where SRP>TP equal to NA and keep ok ones as is
Sample_Data$TPmgLfix[which(c(Sample_Data$TPmgL<Sample_Data$SRPmgL)==TRUE)]="NA"
#
# create new load column for corrected data
Sample_Data$TPLoadmgsfix=Sample_Data$TPLoadmgs
#
# set values of new load column where SRP>TP equal to NA and keep ok ones as is
Sample_Data$TPLoadmgsfix[which(c(Sample_Data$TPmgL<Sample_Data$SRPmgL)==TRUE)]="NA"
#
# NOTE: use 'TPmgLfix' and 'TPLoadmgsfix' from now on for the TP concentration and load data, respectively.
#
#
# -----------------------------------------------------------------
# Sample Queries
#
# see more examples of how to query at https://code.google.com/p/sqldf/
# -----------------------------------------------------------------
# 
# select sample location, season, and TP concentration where the season is autumn
autumnTP=sqldf("SELECT LocationID, Season, TPmgLfix FROM Sample_Data WHERE Season = 'autumn'")
#
# same as previous but without NA values
autumnTPnoNAs=sqldf("SELECT LocationID, Season, TPmgLfix FROM Sample_Data WHERE Season = 'autumn' AND TPmgLfix <> 'NA'")
#
# join the information for the site with information about sample events
spatial1=sqldf("SELECT LocationID, Lat, Long, Waterbody, TPmgLfix FROM Site_Info JOIN Sample_Data USING (LocationID)")
#
# the spatial1 query can also be written as follows using alliasing
spatial2=sqldf("SELECT s.LocationID, Lat, Long, Waterbody, TPmgLfix FROM Site_Info s JOIN Sample_Data d ON s.LocationID=d.LocationID")
# alliasing (s.) only on columns that are the same between both tables
# s. goes with Site_Info and d. goes with Sample_Data or any other allias (could use Site_Info.LocationID too)
# can pick any letter or letter combo (here we use s and d)
# 'USING' is a shortcut command (can also use 'On'), for 'USING' column names MUST be exactly the same!
#
# average TP concentration for each site for each season
avgTPseason=sqldf("SELECT LocationID, Season, Avg(TPmgLfix) AvgTPmgLfix FROM Sample_Data GROUP BY LocationID, Season")
# comma needed to sepearate columns
# if you put AvgTPmgLfix after the Avg() command then it will name the new column with AvgTPmgLfix
# take out one of the group by terms and see how that changes the result
# mean(na.omit(as.numeric(Sample_Data$TPmgLfix[Sample_Data$Season == "autumn"])))
#
# use avgTPseason to plot TP for autumn for different sites
plot(avgTPseason$AvgTPmgLfix[avgTPseason$Season=="autumn"]~avgTPseason$LocationID[avgTPseason$Season=="autumn"], ylab="Average Autumn TP (mg/L)",xlab="",las=2)
#
# calculate the min and max flow of all the data
sqldf("SELECT Min(FlowCFS), Max(FlowCFS) FROM Sample_Data")
#
# calculate the min and max flow where flow is not equal to zero
sqldf("SELECT Min(FlowCFS), Max(FlowCFS) FROM Sample_Data WHERE FlowCFS<>0")
# '<>' means does not equal
#
# select location id, sample date, season and flow >1000 cfs
flowOver1000=sqldf("SELECT LocationID, SampleDate, FlowCFS FROM Sample_Data WHERE FlowCFS > 1000")
#
# selecting by traits and defining categories (i.e. cases)
# select by flow where categorize low as anything less than 100 cfs, med as anything between 100 and 1000 cfs, and high above 1000 cfs
flowCat1=sqldf("SELECT LocationID, SampleDate, FlowCFS, CASE WHEN FlowCFS < 100 THEN 'low' WHEN FlowCFS > 1000 THEN 'high' ELSE 'med' END FlowMag FROM Sample_Data WHERE FlowCFS<>0")
#
# same as flowCat1 but use * to select all columns of Sample_Data instead of only a few
flowCat2=sqldf("SELECT *, CASE WHEN FlowCFS < 100 THEN 'low' WHEN FlowCFS > 1000 THEN 'high' ELSE 'med' END FlowMag FROM Sample_Data WHERE FlowCFS<>0")
#
# look at distribution of cases for different categories using Count()
flowCounts=sqldf("SELECT Count(*), CASE WHEN FlowCFS < 100 THEN 'low' WHEN FlowCFS > 1000 THEN 'high' ELSE 'med' END FlowMag FROM Sample_Data WHERE FlowCFS<>0 GROUP BY 2")
# 
# try other ways to categorize by ajusting cases
flowCat3=sqldf("SELECT Count(*), CASE WHEN FlowCFS < 100 THEN 'low' WHEN FlowCFS > 1000 THEN 'high' ELSE 'med' END FlowMag FROM Sample_Data WHERE FlowCFS<>0 GROUP BY FlowMag")
flowCat4=sqldf("SELECT Count(*), CASE WHEN FlowCFS < 50 THEN 'low' WHEN FlowCFS > 500 THEN 'high' ELSE 'med' END FlowMag FROM Sample_Data WHERE FlowCFS<>0 GROUP BY FlowMag")
#
# include average flow for all cases with counts
flowCat5=sqldf("SELECT Count(*), Avg(FlowCFS), CASE WHEN FlowCFS < 100 THEN 'low' WHEN FlowCFS > 1000 THEN 'high' ELSE 'med' END FlowMag FROM Sample_Data WHERE FlowCFS<>0 GROUP BY FlowMag")
# Case can be used for numbers too i.e. rounding, etc., can compare on row level but not from one row to another
#
# select all TP concentration data from the winter
wintertp1=sqldf("SELECT LocationID, SampleDate, TPmgLfix FROM Sample_Data WHERE Season = 'winter'")
#
# select all columns from TP concentration data from winter
wintertp2=sqldf("SELECT * FROM Sample_Data WHERE Season = 'winter'")
#
# add a column that selects out the year from the date for all TP data in the winter and name it as new column 'SampleYear'
wintertp3=sqldf("SELECT LocationID, substr(SampleDate,Length(SampleDate)-3,4) SampleYear, TPmgLfix FROM Sample_Data WHERE Season = 'winter' AND TPmgLfix <> 'NA'")
#
# same as wintertp3 but make sure data are integers so we can plot them, be careful though because NA's will be turned into zeros
#wintertp4=sqldf("SELECT LocationID, CAST(substr(SampleDate,Length(SampleDate)-3,4) AS INTEGER) SampleYear, CAST(TPmgLfix AS FLOAT) TPmgLfix FROM Sample_Data WHERE Season = 'winter' WHERE TPmgLfix IS NOT 'NA'")
#
# select out only DHB
wintertpDHB=wintertp3[wintertp3$LocationID=="DHB_WRI",]
#
# plot DHB winter TP concentration data by year
# first need to convert characters to numbers using as.numeric()
wintertpDHB.df=data.frame(SampleYear=as.numeric(wintertpDHB$SampleYear),TPmgLfix=as.numeric(wintertpDHB$TPmgLfix))
boxplot(TPmgLfix~SampleYear,data=wintertpDHB.df,xlab="Year",ylab="TP Concentration (mg/L)",main="DHB Winter Samples")
#table(wintertpDHB$SampleYear) #counts per year
#
# select out only Inlet
wintertpInlet=wintertp3[wintertp3$LocationID=="Inlet_WRI",]
#
# plot Inlet winter data by year
# first need to convert characters to numbers and take out NA's
wintertpInlet.df=data.frame(SampleYear=as.numeric(wintertpInlet$SampleYear),TPmgLfix=as.numeric(wintertpInlet$TPmgLfix))
boxplot(TPmgLfix~SampleYear,data=wintertpInlet.df,xlab="Year",ylab="TP Concentration (mg/L)",main="Inlet Winter Samples")
#table(wintertpInlet$SampleYear) #counts per year
#
# select and calculate the average for each year over time for all
wintertpAvg=sqldf("SELECT LocationID, substr(SampleDate,Length(SampleDate)-3,4) SampleYear, Avg(TPmgLfix) AvgTPmgL FROM Sample_Data WHERE Season = 'winter' GROUP BY LocationID, SampleYear")
#
# plot DHB winter data (average) by year
plot(AvgTPmgL[wintertpAvg$LocationID=="DHB_WRI"]~SampleYear[wintertpAvg$LocationID=="DHB_WRI"],data=wintertpAvg,pch=16,xlab="Year",ylab="Average TP Concentration (mg/L)",main="DHB Winter Samples")
#
# plot avearge vs number of samples
wintertpDHBAvg=sqldf("SELECT SampleYear, Avg(TPmgLfix) AvgTPmgLfix FROM wintertpDHB GROUP BY SampleYear")
plot(wintertpDHBAvg$AvgTPmgLfix~c(table(wintertpDHB$SampleYear)),pch=16,main="DHB")
#
# plot Inlet winter data (average) by year
plot(AvgTPmgLfix[wintertpAvg$LocationID=="Inlet_WRI"]~SampleYear[wintertpAvg$LocationID=="Inlet_WRI"],data=wintertpAvg,pch=16,xlab="Year",ylab="Average TP Concentration (mg/L)",main="Inlet Winter Samples")
#
# plot avearge vs number of samples
wintertpInletAvg=sqldf("SELECT SampleYear, Avg(TPmgLfix) AvgTPmgLfix FROM wintertpInlet GROUP BY SampleYear")
plot(wintertpInletAvg$AvgTPmgLfix~c(table(wintertpInlet$SampleYear)),pch=16,main="inlet")
#
#
#