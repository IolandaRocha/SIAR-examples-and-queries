# this demo generates some random data for M consumers based on N samples and
# constructs a standard ellipse for each based on SEAc and SEA_B

rm(list = ls())

library(siar)

# ------------------------------------------------------------------------------
# ANDREW - REMOVE THESE LINES WHICH SHOULD BE REDUNDANT
# change this line
#setwd("c:/rtemp")
#setwd("/Users/andrewjackson/Dropbox/siar/demo scripts and files/siber scripts")
setwd( "D:/Alternative My Documents/Andrews Documents/Dropbox/siar/demo scripts and files/siber scripts")
# ------------------------------------------------------------------------------



# now close all currently open windows
graphics.off()


# read in some data
# NB the column names have to be exactly, "group", "x", "y"
mydata <- read.table("example_ellipse_data.txt",sep="\t",header=T)

# make the column names availble for direct calling
attach(mydata)


# now loop through the data and calculate the ellipses
ngroups <- length(unique(group))



# split the isotope data based on group
spx <- split(x,group)
spy <- split(y,group)

# create some empty vectors for recording our metrics
SEA <- numeric(ngroups)
SEAc <- numeric(ngroups)
TA <- numeric(ngroups)

dev.new()
plot(x,y,col=group,type="p")
legend("topright",legend=as.character(paste("Group ",unique(group))),
        pch=19,col=1:length(unique(group)))

for (j in unique(group)){


  # Fit a standard ellipse to the data
  SE <- standard.ellipse(spx[[j]],spy[[j]],steps=1)
  
  # Extract the estimated SEA and SEAc from this object
  SEA[j] <- SE$SEA
  SEAc[j] <- SE$SEAc
  
  # plot the standard ellipse with d.f. = 2 (i.e. SEAc)
  # These are plotted here as thick solid lines
  lines(SE$xSEAc,SE$ySEAc,col=j,lty=1,lwd=3)
  
  
  # Also, for comparison we can fit and plot the convex hull
  # the convex hull is plotted as dotted thin lines
  #
  # Calculate the convex hull for the jth group's isotope values
  # held in the objects created using split() called spx and spy
  CH <- convexhull(spx[[j]],spy[[j]])
  
  # Extract the area of the convex hull from this object
  TA[j] <- CH$TA
  
  # Plot the convex hull
  lines(CH$xcoords,CH$ycoords,lwd=1,lty=3)

  
}

# print the area metrics to screen for comparison
# NB if you are working with real data rather than simulated then you wont be
# able to calculate the population SEA (pop.SEA)
# If you do this enough times or for enough groups you will easily see the
# bias in SEA as an estimate of pop.SEA as compared to SEAc which is unbiased.
# Both measures are equally variable.
print(cbind(SEA,SEAc,TA))

# So far we have fitted the standard ellipses based on frequentist methods
# and calculated the relevant metrics (SEA and SEAc). Now we turn our attention
# to producing a Bayesian estimate of the standard ellipse and its area SEA_B


reps <- 10^4 # the number of posterior draws to make

# Generate the Bayesian estimates for the SEA for each group using the 
# utility function siber.ellipses
SEA.B <- siber.ellipses(x,y,group,R=reps)

# ------------------------------------------------------------------------------
# Plot out some of the data and results
# ------------------------------------------------------------------------------


# Plot the credible intervals for the estimated ellipse areas now
# stored in the matrix SEA.B
dev.new()
siardensityplot(SEA.B,
  xlab="Group",ylab="Area (permil^2)",
  main="Different estimates of Standard Ellipse Area (SEA)")

# and now overlay the other metrics on teh same plot for comparison
points(1:ngroups,SEAc,pch=15,col="red")
legend("topright",c("SEAc"),pch=c(15,17),col=c("red","blue"))

# ------------------------------------------------------------------------------
# Compare two ellipses for significant differences in SEA
# ------------------------------------------------------------------------------

# to test whether Group 1 SEA is smaller than Group 2...
# you need to calculate the proportion of G1 ellipses that are less 
# than G2

Pg2.gt.g3 <- sum( SEA.B[,1] < SEA.B[,2] ) / nrow(SEA.B)

# In this case, all the posterior ellipses for G1 are less than G2 so 
# we can conclude that G1 is smaller than G2 with p approx = 0, and 
# certainly p < 0.0001.

# and for G1 < G3
Pg3.gt.g1 <- sum( SEA.B[,1] < SEA.B[,3] ) / nrow(SEA.B)

# etc...
Pg2.gt.g3 <- sum( SEA.B[,2] > SEA.B[,3] ) / nrow(SEA.B)



# ------------------------------------------------------------------------------
# To calculate the overlap between two ellipses you can use the following code
# NB: the degree of overlap is sensitive to the size of ellipse you 
# choose to draw around each group of data. However, regardless of the choice
# of ellipse, the extent of overlap will range from 0 to 1, with values closer
# to 1 representing more overlap. So, at worst it is a semi-quantitative 
# measure regardless of extent of the ellipse, but the finer detials and 
# magnitudes of the effect size will be sensitive to this choice.
#
# Additional coding will be required if you wish to calculate the overlap 
# between ellipses other than those described by SEA or SEAc. 
# ------------------------------------------------------------------------------

# The overlap between the SEAc for groups 1 and 3 is given by:

# Fit a standard ellipse to the data
# NB, I use a small step size to make sure i get more "round" ellipses,
# as this method is computatonal and based on the discretisation of the
# ellipse boundaries.

overlap.G1.G3 <- overlap(spx[[1]],spy[[1]],spx[[3]],spy[[3]],steps=1)

#-------------------------------------------------------------------------------
# you can also cacluate the overlap between two of the convex hulls,
# or indeed any polygon using the code that underlies the overlap() function.

# fit a hull to the Group 1 data
hullG1 <- convexhull(spx[[1]],spy[[1]])

# create a list object of the unique xy coordinates of the hull
# the first and last entries are coincident for plotting, so ignore the first...
# hence the code to subset [2:length(hullG1$xcoords)] 
h1 <- list( x = hullG1$xcoords[2:length(hullG1$xcoords)] , y = hullG1$ycoords[2:length(hullG1$xcoords)] )

# Do the same for the Group 3 data
hullG3 <- convexhull(spx[[3]],spy[[3]])
h3 <- list( x = hullG3$xcoords[2:length(hullG3$xcoords)] , y = hullG3$ycoords[2:length(hullG3$xcoords)] )

# and calculate the overlap using the function in spatstat package.
hull.overlap.G1.G3 <- overlap.xypolygon(h1,h3)
