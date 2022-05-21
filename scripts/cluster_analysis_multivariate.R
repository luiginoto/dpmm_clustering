library(dirichletprocess)
library(Hmisc)
library(scatterplot3d)

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

summary(data_cont)
sapply(data_cont, sd, na.rm = TRUE)
hist.data.frame(data_cont) # press "Finish" on the Plots tab to continue running the script

# re-define dataframe id
rownames(data_cont) <- 1:nrow(data_cont)
boxplot(data_cont)

# scale the data and apply PCA
data_scaled_pca <- prcomp(data_cont, center = TRUE, scale. = TRUE)
summary(data_scaled_pca)

# keep the first 2 principal components
data_3d <- data.frame(data_scaled_pca$x)[,1:3]
data_3d <- sapply(data_3d, as.numeric)

scatterplot3d(data_3d[,1:3])

pc1_mean <- mean(data_3d[,1])
pc2_mean <- mean(data_3d[,2])
pc3_mean <- mean(data_3d[,3])

# define parameters of base distribution in the DP prior
g0Priors <- list(mu0 = c(pc1_mean, pc2_mean, pc3_mean), # rep_len(0, length.out = 2)
                 Lambda = diag(3),
                 kappa0 = 3,
                 nu = 3)

# DP mixture of multivariate normal distributions (2 dimensions)
dp <- DirichletProcessMvnormal(data_3d, g0Priors)

# run MCMC (2500 MC states)
dp <- Fit(dp, 2500)

# plot clustering corresponding to the last MCMC sample
scatterplot3d(data_3d[,1:3], pch = 16, color=unlist(dp$labelsChain[2500]))
legend("topright", legend=c(1:max(unlist(dp$labelsChain[2500]))),
       col=c(1:max(unlist(dp$labelsChain[2500]))), pch=16)

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
     ylim=c(0,1),
     ylab='Empirical probability in MCMC samples',
     xlab ='Number of clusters',
     lty=3)
points(num_clusters, freq,
       type="p", 
       ylab='Empirical probability in MCMC samples',
       xlab ='Number of clusters',
       pch=16)

map_estimate <- num_clusters[which(freq == max(freq))]




