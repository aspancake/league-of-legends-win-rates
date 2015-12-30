# ------------------------------------------------   #
# A Look at Data Retrieved from Riot's API           #         
# 1) Comparing distribution of game lengths by patch #
# 2) Looking at champion win rates over time         #
# ------------------------------------------------   #


# --------------------------------------------------- #
# Additional Data Manipulation # 
# --------------------------------------------------- #


library(sqldf)
library(RPostgreSQL)
library(plyr)

# Retrieve data (In this case, connect to PostgreSQL and retrieve table)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="...",host="...",port=... ,user="...")
patch_18 <- dbReadTable(con, "merged_18")
patch_22 <- dbReadTable(con,"merged_22")
dbDisconnect(con)

# Get a Champ ID reference table (Connects champion ids to actual names)
setwd('...')
id_ref <- read.csv('champ_id.csv',header=FALSE)
colnames(id_ref)[1] <- "ChampId"
colnames(id_ref)[2] <- "ChampName"

# Inner join to get champ names
patch_18 <- sqldf("SELECT d.*, b.ChampName
                  FROM patch_18 d
                  INNER JOIN id_ref b
                  ON (d.champ = b.ChampId)",drv="SQLite") 

patch_22 <- sqldf("SELECT d.*, b.ChampName
                  FROM patch_22 d
                  INNER JOIN id_ref b
                  ON (d.champ = b.ChampId)",drv="SQLite") 

# Notice that we have multiple accounts of a single match, let's remove that issue
patch_18 <- sqldf("SELECT * FROM patch_18 GROUP BY ChampName, match_id",drv="SQLite")
patch_22 <- sqldf("SELECT * FROM patch_22 GROUP BY ChampName, match_id",drv="SQLite")

# Summarize the Data
summ_18 <- ddply(patch_18,c("ChampName","time_group"),summarise,mean=mean(outcome),N = length(outcome))
summ_22 <- ddply(patch_22,c("ChampName","time_group"),summarise,mean=mean(outcome),N = length(outcome))

# Find the king of early, king of late
king_early_18 <- sqldf("SELECT * FROM summ_18 WHERE (N>60) AND (time_group=1) AND (mean>.58)",drv="SQLite")
king_early_22 <- sqldf("SELECT * FROM summ_22 WHERE (N>60) AND (time_group=1) AND (mean>.58)",drv="SQLite")

king_late_18 <- sqldf("SELECT * FROM summ_18 WHERE (N>60) AND (time_group=5) AND (mean>.58)",drv="SQLite")
king_late_22 <- sqldf("SELECT * FROM summ_22 WHERE (N>50) AND (time_group=5) AND (mean>.58)",drv="SQLite")

# --------------------------------------------------- #
# Graphics # 
# --------------------------------------------------- #

library(ggplot2)
library(png)
library(gridGraphics)

# 1) Compare time distributions

avg_18 <- mean(patch_18$time)
sd_18 <- sd(patch_18$time)

avg_22 <- mean(patch_22$time)
sd_22 <- sd(patch_22$time)

ggplot(patch_18,aes(x=time)) + 
  geom_histogram(aes(y=..density..),binwidth=1,color="black",fill="orange",alpha=.3) +
  geom_vline(aes(xintercept=mean(time,na.rm=T)),color="black",linetype="dashed",size=1) +
  coord_cartesian(ylim=c(.0,.08),xlim=c(10,60)) +
  scale_x_continuous(name="Match Duration (Mins)",breaks=seq(0,60,10),expand=c(0,0)) +
  scale_y_continuous(name="% of Matches",breaks=seq(0,.08,.02),expand=c(0,0)) +
  theme_bw() +
  theme(panel.grid.minor=element_blank(),
        panel.grid.major=element_blank()) +
  annotate("text", label = "Mean 29.95", x=55, y=.075) +
  annotate("text", label = "Standard Deviation 7.33", x=51, y=.07)

ggplot(patch_22,aes(x=time)) + 
  geom_histogram(aes(y=..density..),binwidth=1,color="black",fill="purple",alpha=.3) +
  geom_vline(aes(xintercept=mean(time,na.rm=T)),color="black",linetype="dashed",size=1) +
  coord_cartesian(ylim=c(.0,.08),xlim=c(10,60)) +
  scale_x_continuous(name="Match Duration (Mins)",breaks=seq(0,60,10),expand=c(0,0)) +
  scale_y_continuous(name="% of Matches",breaks=seq(0,.08,.02),expand=c(0,0)) +
  theme_bw() +
  theme(panel.grid.minor=element_blank(),
        panel.grid.major=element_blank())  +
  annotate("text", label = "Mean 28.43", x=55, y=.075) +
  annotate("text", label = "Standard Deviation 6.84", x=51, y=.07)

# 2) Both patches - Vaynes win rate over time

full_vayne <- sqldf("SELECT * FROM patch_18 WHERE ChampName='Vayne' UNION SELECT * FROM patch_22 WHERE ChampName='Vayne'",drv="SQLite")
vayne_avg <- as.numeric(sqldf("SELECT avg(outcome) FROM full_vayne",drv="SQLite"))
vayne_summ <- ddply(full_vayne,c("ChampName","time_group"),summarise,mean=mean(outcome),N=length(outcome))
img <- readPNG(".../VayneSquare.png")
g <- rasterGrob(img, interpolate=TRUE)

ggplot(vayne_summ,aes(x=time_group,y=mean)) + 
  annotation_custom(g,xmin=4,xmax=5.5,ymin=.6,ymax=.65) +
  geom_line(color="black",size=1) +
  geom_area(alpha=.5,fill="purple") +
  geom_point(color="black",size=4) +
  geom_point(color="purple",size=3) +
  coord_cartesian(ylim=c(.35,.65),xlim=c(1,5)) +
  geom_hline(yintercept=vayne_avg,size=1,color="black",linetype="dashed") +
  scale_x_continuous(name="Match Duration",breaks=seq(1,5,2),expand=c(0,0),labels=c("                   Early Game","Mid Game","Late Game                   ")) +
  scale_y_continuous(name="Average Win Rate (%)",expand=c(0,0),breaks=seq(.4,.6,.1)) +
  theme_bw() +
  theme(panel.grid.minor=element_blank(),
        panel.grid.major=element_blank()) +
  annotate("text", label = "Overall Win Rate 51%", x=3.82, y=.64) +
  annotate("text",label="Vayne (5.18 & 5.22)", x=3.82, y=.62)

# 3) Patch 5.18 - Braum

braum_18 <- sqldf("SELECT * FROM patch_18 WHERE ChampName='Braum'",drv="SQLite")
braum_avg <- as.numeric(sqldf("SELECT avg(outcome) FROM braum_18",drv="SQLite"))
braum_summ <- ddply(braum_18,c("ChampName","time_group"),summarise,mean=mean(outcome),N=length(outcome))
img <- readPNG(".../BraumSquare.png")
g <- rasterGrob(img, interpolate=TRUE)


ggplot(braum_summ,aes(x=time_group,y=mean)) + 
  annotation_custom(g,xmin=4,xmax=5.5,ymin=.6,ymax=.65) +
  geom_line(color="black",size=1) +
  geom_area(alpha=.5,fill="turquoise3") +
  geom_point(color="black",size=4) +
  geom_point(color="turquoise3",size=3) +
  coord_cartesian(ylim=c(.35,.65),xlim=c(1,5)) +
  geom_hline(yintercept=braum_avg,size=1,color="black",linetype="dashed") +
  scale_x_continuous(name="Match Duration",breaks=seq(1,5,2),expand=c(0,0),labels=c("                   Early Game","Mid Game","Late Game                   ")) +
  scale_y_continuous(name="Average Win Rate (%)",expand=c(0,0),breaks=seq(.4,.6,.1)) +
  theme_bw() +
  theme(panel.grid.minor=element_blank(),
        panel.grid.major=element_blank()) +
  annotate("text", label = "Overall Win Rate 50%", x=3.82, y=.64) +
  annotate("text",label="Braum (5.18)", x=3.82, y=.62)

# 4) Patch 5.22 - Miss Fortune

mf_22 <- sqldf("SELECT * FROM patch_22 WHERE ChampName='Miss Fortune'",drv="SQLite")
mf_avg <- as.numeric(sqldf("SELECT avg(outcome) FROM mf_22",drv="SQLite"))
mf_summ <- ddply(mf_22,c("ChampName","time_group"),summarise,mean=mean(outcome),N=length(outcome))
img <- readPNG(".../MissFortuneSquare.png")
g <- rasterGrob(img, interpolate=TRUE)

ggplot(mf_summ,aes(x=time_group,y=mean)) + 
  annotation_custom(g,xmin=4,xmax=5.5,ymin=.6,ymax=.65) +
  geom_line(color="black",size=1) +
  geom_area(alpha=.5,fill="red3") +
  geom_point(color="black",size=4) +
  geom_point(color="red3",size=3) +
  coord_cartesian(ylim=c(.35,.65),xlim=c(1,5)) +
  geom_hline(yintercept=mf_avg,size=1,color="black",linetype="dashed") +
  scale_x_continuous(name="Match Duration",breaks=seq(1,5,2),expand=c(0,0),labels=c("                   Early Game","Mid Game","Late Game                   ")) +
  scale_y_continuous(name="Average Win Rate (%)",expand=c(0,0),breaks=seq(.4,.6,.1)) +
  theme_bw() +
  theme(panel.grid.minor=element_blank(),
        panel.grid.major=element_blank()) +
  annotate("text", label = "Overall Win Rate 57%", x=3.85, y=.64) +
  annotate("text",label="Miss Fortune (5.22)", x=3.85, y=.62)

