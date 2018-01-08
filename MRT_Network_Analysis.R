install.packages("rvest")
library(rvest)

### F12 Developer Mode located table html tag -> copy XPath

url <- "https://en.wikipedia.org/wiki/List_of_Singapore_MRT_stations"
mrt_stn <-  url %>%
  read_html() %>%
  html_nodes(xpath='//*[@id="mw-content-text"]/div/table[2]') %>%
  html_table(fill = TRUE)
mrt <- mrt_stn[[1]]
mrt <- mrt[,c(1:2,5,7:8)] 
names(mrt) <- c("Code","Name","Opening","Status","Location")
mrt <- subset(mrt,Code != Name)
mrt <- mrt[2:nrow(mrt),]

mrt$Code <- substr(mrt$Code, 1, 4)
mrt$Code <- iconv(mrt$Code, "ASCII", "UTF-8", sub="")

mrt$Name <- gsub('\\[.\\]',"",mrt$Name)

mrt <- mrt[mrt$Name != 'Reserved Station',]
mrt <- mrt[mrt$Name != 'Punggol Coast',]
mrt <- mrt[mrt$Status != 'TBA',]


#########
# MRT NSL Edgelist
ns_df <- mrt[substr(mrt$Code,1,2) == 'NS',]

sourceList <- ""
targetList <- ""
for (i in 1:nrow(ns_df)-1) {
  sourceList[i] <- ns_df$Name[i]
  targetList[i] <- ns_df$Name[i+1]
}

ns_edgelist <- data.frame(sourceList, targetList, "NSL")
names(ns_edgelist) <- c("source", "target", "network")

# MRT EWL Edgelist
ew_df <- mrt[substr(mrt$Code,1,2) == 'EW',]

sourceList <- ""
targetList <- ""
for (i in 1:nrow(ew_df)-1) {
  sourceList[i] <- ew_df$Name[i]
  targetList[i] <- ew_df$Name[i+1]
}

ew_edgelist <- data.frame(sourceList, targetList, "EWL")
names(ew_edgelist) <- c("source", "target", "network")

# MRT CAL Edgelist
cg_df <- mrt[substr(mrt$Code,1,2) == 'CG',]

sourceList <- ""
targetList <- ""
for (i in 1:nrow(cg_df)-1) {
  sourceList[i] <- cg_df$Name[i]
  targetList[i] <- cg_df$Name[i+1]
}

cg_edgelist <- data.frame(sourceList, targetList, "CAL")
names(cg_edgelist) <- c("source", "target", "network")


# MRT NEL Edgelist
ne_df <- mrt[substr(mrt$Code,1,2) == 'NE',]

sourceList <- ""
targetList <- ""
for (i in 1:nrow(ne_df)-1) {
  sourceList[i] <- ne_df$Name[i]
  targetList[i] <- ne_df$Name[i+1]
}

ne_edgelist <- data.frame(sourceList, targetList, "NEL")
names(ne_edgelist) <- c("source", "target", "network")


# MRT CCL Edgelist
cc_df <- mrt[substr(mrt$Code,1,2) == 'CC',]

sourceList <- ""
targetList <- ""
for (i in 1:nrow(cc_df)-1) {
  sourceList[i] <- cc_df$Name[i]
  targetList[i] <- cc_df$Name[i+1]
}

cc_edgelist <- data.frame(sourceList, targetList, "CCL")
names(cc_edgelist) <- c("source", "target", "network")


# MRT DTL Edgelist
dt_df <- mrt[substr(mrt$Code,1,2) == 'DT',]

sourceList <- ""
targetList <- ""
for (i in 1:nrow(dt_df)-1) {
  sourceList[i] <- dt_df$Name[i]
  targetList[i] <- dt_df$Name[i+1]
}

dt_edgelist <- data.frame(sourceList, targetList, "DTL")
names(dt_edgelist) <- c("source", "target", "network")


mrt_edgelist <- rbind(ns_edgelist,ew_edgelist,cg_edgelist,ne_edgelist,cc_edgelist,dt_edgelist)
mrt_edgelist$target <- as.character(mrt_edgelist$target)
mrt_edgelist$source <- as.character(mrt_edgelist$source)
mrt_edgelist$network <- as.character(mrt_edgelist$network)
mrt_edgelist[nrow(mrt_edgelist)+1,] <- c("Bayfront","Marina Bay","CEL")
mrt_edgelist[nrow(mrt_edgelist)+1,] <- c("Bayfront","Promenade","CCL")
mrt_edgelist[nrow(mrt_edgelist)+1,] <- c("Tanah Merah","Expo","CAL")
mrt_edgelist$type <- "undirected"


mrt_node <- mrt[substr(mrt$Code,1,2) != 'TE',]
names(mrt_node)[2] <- "id"
mrt_node$label <- mrt_node$id

mrt_nodes <- unique(mrt_node)
mrt_nodes <- mrt_nodes[!duplicated(mrt_nodes$id),]
mrt_nodes$Code <- substr(mrt_nodes$Code, 1, 2)

write.csv(mrt_nodes, file="mrt_nodes.csv", row.names=F)


install.packages("igraph")
library(igraph)

# rename for igraph edgelist format
names(mrt_edgelist) <- c("from","to","network","type")
mrt_nodes <- mrt_nodes[c(2,6,1,3,4,5)]

g = graph.data.frame(mrt_edgelist, mrt_nodes, directed=F)

# checking if multiple edges exists in the graph network
any_multiple(g)
which_multiple(g)
# Removing multiple edges to create a simplified graph 
E(g)[38]
E(g)[135]

simple_g <- g
simple_g <- delete_edges(simple_g,c(38,135))
any_multiple(simple_g) 

#### descriptive statistics ####
# list nodes & edges attributes
list.vertex.attributes(simple_g)
list.edge.attributes(simple_g)

# easy access to nodes, edges, and their attributes 
E(simple_g)       # The edges of the graph object
V(simple_g)       # The vertices of the graph object

# Network Size (num of nodes and edges)
summary(simple_g)
# Network Density
graph.density(simple_g,loop=FALSE)
# Greatest distance between any pair of vertices
diameter(simple_g)
# Average Path Length
mean_distance(simple_g, directed=F)
# Length of all paths in the graph
distances(simple_g)


### Generating graph attributes ###
V(simple_g)$degree=degree(simple_g, mode="all")
V(simple_g)$betweenness=betweenness(simple_g,normalized=T)
V(simple_g)$closeness=closeness(simple_g,normalized=T)

V(simple_g)$coreness=coreness(simple_g)
V(simple_g)$eigen=evcent(simple_g)$vector

# Specify graph layout to use
glay = layout_with_lgl(simple_g)
glay = layout_on_sphere(simple_g)

install.packages("plyr")
library(plyr)
# Generate node colors based on edge:network attribute
E(simple_g)$color <- mapvalues(E(simple_g)$network, c("NSL","EWL","CAL","NEL","CCL","DTL","CEL"), c("#D42E12","#009645","#009645","#9900AA","#FA9E0D","#FA9E0D","#005EC4"))
#V(g)$size <- deg*3

# plot degree graph 
plot(simple_g, layout=glay, edge.color=E(simple_g)$color, edge.width=3, edge.curve=1, 
     vertex.label.cex=.7, vertex.color="white", vertex.frame.color="black", 
     vertex.label.font=1.5, vertex.label=V(simple_g)$label, vertex.label.color="grey40",
     vertex.size=V(simple_g)$degree*3.5) 
# show the node(s) that holds the largest degree value
V(simple_g)$name[degree(simple_g)==max(degree(simple_g))]

# plot closeness graph
plot(simple_g, layout=glay, edge.color=E(simple_g)$color, edge.width=3, edge.curve=1, 
     vertex.label.cex=.7, vertex.color="white", vertex.frame.color="black", 
     vertex.label.font=.7, vertex.label=V(simple_g)$label, vertex.label.color="grey40",
     vertex.size=V(simple_g)$closeness*90) 
# show the node(s) that holds the largest closeness value
V(simple_g)$name[closeness(simple_g)==max(closeness(simple_g))]

# plot betweenness graph
plot(simple_g, layout=glay, edge.color=E(simple_g)$color, edge.width=3, edge.curve=1, 
     vertex.label.cex=.7, vertex.color="white", vertex.frame.color="black", 
     vertex.label.font=1, vertex.label=V(simple_g)$label, vertex.label.color="grey40",
     vertex.size=V(simple_g)$betweenness*60) 
# show the node(s) that holds the largest betweenness value
V(simple_g)$name[betweenness(simple_g)==max(betweenness(simple_g))]

# plot eigenvector graph
plot(simple_g, layout=glay, edge.color=E(simple_g)$color, edge.width=3, edge.curve=1, 
     vertex.label.cex=.7, vertex.color="white", vertex.frame.color="black", 
     vertex.label.font=1, vertex.label=V(simple_g)$label, vertex.label.color="grey40",
     vertex.size=V(simple_g)$eigen*20)
# show the node(s) that holds the largest eigenvector value
V(simple_g)$name[which.max(V(simple_g)$eigen)]

attr = data.frame(row.names=V(simple_g)$name,degree=V(simple_g)$degree,
                  coreness=V(simple_g)$coreness,betweenness=V(simple_g)$betweenness,
                  closeness=V(simple_g)$closeness,eigen=V(simple_g)$eigen)


############################################
######### basic statistic analysis #########
#### descriptive ####
table(attr$degree)
table(attr$coreness)
table(attr$betweenness)
table(attr$closeness)
table(attr$eigen)

attr



