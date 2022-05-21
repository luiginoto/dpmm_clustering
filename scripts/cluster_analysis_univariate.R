library(dirichletprocess)
library(Hmisc)

set.seed(5)

# dataset available at http://archive.ics.uci.edu/ml/datasets/Wholesale+customers

data = read.csv(".../Wholesale customers data.csv", header=T, sep=",", stringsAsFactors = FALSE)

# keep the continuous variables
data_cont <- data[,3:ncol(data)]
summary(data_cont) 
boxplot(data_cont)

hist.data.frame(data_cont) # press "Finish" on the Plots tab to continue running the script

# eliminate outliers
for(i in colnames(data_cont)){
  print(i)
  outliers <- boxplot(data_cont[[i]], plot=FALSE)$out
  data_cont <- data_cont[-which(data_cont[[i]] %in% outliers),]
}

hist.data.frame(data_cont) # press "Finish" on the Plots tab to continue running the script
sapply(data_cont, sd, na.rm = TRUE)

# re-define dataframe id
rownames(data_cont) <- 1:nrow(data_cont)
boxplot(data_cont)

data_grocery <- data_cont[,3]

# scale the data
data_grocery_scaled <- as.numeric(scale(data_grocery))

# define parameters of base distribution in the DP prior
g0Priors = c(0, 1, 1, 1)

# DP mixture of normal distributions (1 dimension)
dp <- DirichletProcessGaussian(data_grocery_scaled, g0Priors)

# run MCMC (2500 MC states)
dp <- Fit(dp, 2500)

plot(dp, data_method="hist")

# define a vector with the number of clusters at each MCMC sample
numclusters_chain <- c()
for(i in 1:2500){
  k = max(unlist(dp$labelsChain[i]))
  numclusters_chain <- c(numclusters_chain, k)
}

# compute empirical distribution of the number of clusters
emp_distr_numclusters <- as.data.frame(table(numclusters_chain)/2500)

num_clusters <- as.double(emp_distr_numclusters$numclusters_chain)
freq <- as.double(emp_distr_numclusters$Freq)

plot(num_clusters, freq,
     type="h", 
     ylab='Empirical probability in MCMC samples',
     xlab ='Number of clusters',
     lty=3)
points(num_clusters, freq,
     type="p", 
     ylab='Empirical probability in MCMC samples',
     xlab ='Number of clusters',
     pch=16)

map_estimate <- num_clusters[which(freq == max(freq))]
