df2GRanges <- function(data, colNames=NULL, format="", ...){
    if (missing(data)){
        stop("data is required!")
    }
    if ((class(data) != "data.frame") || dim(data)[2] <3)
    {
        stop("No valid data passed in. For example a data frame as BED format 
             file with at least 3 fields in the order of: chromosome, start and end. 
             Optional fields are name, score and strand etc. 
             Please refer to http://genome.ucsc.edu/FAQ/FAQformat#format1 for details.")
    }
    if(is.null(colNames)) colNames <- colnames(data)
    colNames_space <- 
        tolower(colNames) %in% c("space", "seqnames", "chr", "chrom", 
                                 "chromosome", "chromosomes")
    if(length(sum(colNames_space))==1){
        colNames[colNames_space] <- "space"
    }
    colNames <- gsub("^start$", "start", colNames, ignore.case=TRUE)
    colNames <- gsub("^end$", "end", colNames, ignore.case=TRUE)
    if(!all(c("space","start","end") %in% colNames)){
        stop("colname must contain space/seqnames, start and end.")
    }
    if(length(colNames)<ncol(data)) 
        stop("the length of colNames is less than number of columns of data")
    colnames(data) <- colNames[1:ncol(data)]
    
    getCol <- function(pattern, words, default){
        ss <- grep(pattern, colnames(data), ignore.case=TRUE)
        if(length(ss)>1) 
            stop(paste("input data has multiple columns for",words,"information"))
        if(length(ss)==1){
            re <- data[,ss]
            data[, ss] <<- NULL 
        }else{
            re <- default
        }
        re
    }
    ##prepare strand
    strand <- getCol("^strand$", "strand", "*")
    strand <- formatStrand(strand)
    
    ##prepare name, memory comsume step. TODO, change it.
    names <- getCol("^name(s)?$", "names", NA)
    if(any(is.na(names)) || any(duplicated(names))) {
        message("duplicated or NA names found. Rename all the names by numbers.")
        ## formatC has memory leak
        n <- nrow(data)
        names <- sprintf(paste("X%0",nchar(as.character(n)),"d", sep=""), 1:n)
    }
    names <- make.names(names)
    
    ##prepare score
    #   score <- getCol("^score$", "score", 1L)
    #   if(length(score)==1) score <- rep(1, nrow(data))
    #   if(all(is.na(score))) score <- rep(1, nrow(data))
    #   score <- as.numeric(as.character(score))
    
    ##prepare start, end, seqnames
    start <- data$start
    end <- data$end
    seqnames <- data$space
    if(!is.numeric(start[1])) start <- as.numeric(as.character(start))
    if(!is.numeric(end[1])) end <- as.numeric(as.character(end))
    if(!is.character(seqnames[1])) seqnames <- as.character(data$space)
    
    gr <- GRanges(seqnames=seqnames, 
                  ranges=IRanges(start=start, 
                                 end=end, 
                                 names = names), 
                  strand=strand)
    rm(list=c("start", "end", "names", "strand", "seqnames"))
    metadata <- colnames(data)
    metadata <- metadata[!metadata %in% c("seqnames", "space", "ranges", 
                                          "strand", "seqlevels", 
                                          "seqlengths", "isCircular", 
                                          "genome", "start", 
                                          "end", "width", "element")]
    for(col in metadata){
        mcols(gr)[,col]<-data[,col]
    }
    rm(data)
    #  gc(verbose=FALSE, reset=TRUE)
    if(format=="BED"){ 
        start(gr) <- start(gr) + 1 ## bed file is (start, end]
        if(length(gr$thickStart)>0 &
           length(gr$thickEnd)>0){
            gr$thick <- IRanges(gr$thickStart+1, gr$thickEnd)
            gr$thickStart <- NULL
            gr$thickEnd <- NULL
        }
        if(length(gr$itemRgb)>0) {## itemRgb, 255,0,0
            itemRgb <- do.call(rbind, strsplit(as.character(gr$itemRgb), ","))
            gr$itemRgb <- NULL
            if(ncol(itemRgb)==3){
                itemRgb <- apply(itemRgb, 1, function(.ele){
                    .ele <- as.numeric(.ele)
                    rgb(.ele[1], .ele[2], .ele[3], maxColorValue = 255)
                })
                gr$itemRgb <- itemRgb
            }else{
                gr$itemRgb <- NA
            }
        }
        if(length(gr$blockCount)>0 & 
           length(gr$blockSizes)>0 &
           length(gr$blockStarts)>0){
            blocksizes <- strsplit(as.character(gr$blockSizes), ",")
            blockstarts <- strsplit(as.character(gr$blockStarts), ",")
            blocks <- mapply(function(num, sizes, starts){
                sizes <- as.integer(sizes)[1:num]
                starts <- as.integer(starts)[1:num]
                ir <- IRanges(starts+1, width=sizes)
                return(ir)
            }, gr$blockCount, blocksizes, blockstarts, SIMPLIFY=FALSE)
            gr$blocks <- IRangesList(blocks)
            gr$blockCount <- NULL
            gr$blockSizes <- NULL
            gr$blockStarts <- NULL
        }
    }
    return(gr)
}

switchColNames <- function(format=c("BED", "GFF",  
                                    "MACS", "MACS2", 
                                    "narrowPeak", "broadPeak",
                                    "others"), colNames=NULL){
    format <- match.arg(format)
    switch(format,
           BED=c("space", "start", "end", "names", 
                 "score", "strand", "thickStart", 
                 "thickEnd", "itemRgb", "blockCount", 
                 "blockSizes", "blockStarts"),
           GFF=c("space", "source", "names", "start", 
                 "end", "score", "strand", "frame", "group"),
           MACS=c("space", "start", "end", "length", 
                  "summit", "tags", "qvalue", 
                  "fold_enrichment", "FDR"),
           MACS2=c("space", "start", "end", "length", 
                   "abs_summit", "pileup", "qvalue", 
                   "fold_enrichment", "FDR", "names"),
           narrowPeak=c("space", "start", "end", "names", 
                        "score", "strand", "signalValue", 
                        "pValue", "qValue", "peak"),
           broadPeak=c("space", "start", "end", "names", 
                       "score", "strand", "signalValue", 
                       "pValue", "qValue"),
           others=colNames,
           colNames)
}

setGeneric("toGRanges", function(data, ...) standardGeneric("toGRanges"))
setMethod("toGRanges", "data.frame", 
          function(data, colNames=NULL, ...){
              this.call <- match.call(expand.dots=TRUE)
              this.call[[1]] <- df2GRanges
              if(length(this.call$format)==0) this.call$format <- "data.frame"
              gr <- eval(this.call, parent.frame())
              return(gr)
})

setMethod("toGRanges", "RangedData", 
          function(data, ...){
              ## RangedData to data.frame
              data <- as.data.frame(data)
              ## data colNames should be
              ## space, start, end, width, names, ...
              data$width <- NULL
              colNames <- colnames(data)
              format <- "RangedData"
              gr <- df2GRanges(data, colNames, format, ...)
              return(gr)
          })

setMethod("toGRanges", "connection", 
          function(data, format=c("BED", "GFF",  
                                  "MACS", "MACS2", 
                                  "narrowPeak", "broadPeak",
                                  "others"), 
                   header=FALSE, comment.char="#", colNames=NULL, ...){
              format <- match.arg(format)
              colNames <- switchColNames(format, colNames)
              if(is.null(colNames)) 
                  stop("colNames is required for unkown format.")
              if(format %in% c("narrowPeak", "broadPeak")){
                  data <- read.table(data, header=FALSE, 
                                     fill=TRUE, stringsAsFactors=FALSE)
                  data <- data[!grepl("track|browser", data[, 1]), 1:ncol(data)]
                  classes <- c("character", "integer", "integer", "character", 
                               "integer", "character", "numeric", "numeric", 
                               "numeric", "integer")[1:ncol(data)]
                  for(i in 1:ncol(data)){ 
                      class(data[, i]) <- mode(data[, i]) <- classes[i]
                  }
              }else{
                  if(format %in% c("MACS", "MACS2")){
                      header <- TRUE
                      comment.char <- "#"
                  }
                  data <- read.table(data, header=header, 
                                     comment.char=comment.char,
                                     ...)
              }
              nc <- min(length(colNames), ncol(data))
              data <- data[, 1:nc, drop=FALSE]
              colNames <- colNames[1:nc]
              colnames(data) <- colNames
              gr <- df2GRanges(data, colNames, format, ...)
              return(gr)
          })

setMethod("toGRanges", "TxDb", 
          function(data, feature=c("gene", "transcript", "exon",
                                   "CDS", "fiveUTR", "threeUTR",
                                   "microRNA", "tRNAs", "geneModel"),
                   OrganismDb, ...){
              feature <- match.arg(feature)
              if(!missing(OrganismDb)) {
                  return(TxDb2GR(data, feature, OrganismDb))
              }else{
                  return(TxDb2GR(data, feature))
              }
          })

setMethod("toGRanges", "EnsDb", 
          function(data, 
                   feature=c("gene", "transcript", "exon", "disjointExons"),
                   ...){
              feature <- match.arg(feature)
              return(EnsDb2GR(data, feature))
          })

setMethod("toGRanges", "character", 
          function(data, format=c("BED", "GFF",  
                                  "MACS", "MACS2", 
                                  "narrowPeak", "broadPeak",
                                  "others"), 
                   header=FALSE, comment.char="#", colNames=NULL, ...){
              format <- match.arg(format)
              if(format %in% c("narrowPeak", "broadPeak")){
                  data <- read.table(data, header=FALSE, 
                                     fill=TRUE, stringsAsFactors=FALSE)
                  data <- data[!grepl("track|browser", data[, 1]), 1:ncol(data)]
                  classes <- c("character", "integer", "integer", "character", 
                               "integer", "character", "numeric", "numeric", 
                               "numeric", "integer")[1:ncol(data)]
                  for(i in 1:ncol(data)){ 
                      class(data[, i]) <- mode(data[, i]) <- classes[i]
                  }
              }else{
                  if(format %in% c("MACS", "MACS2")){
                      header <- TRUE
                      comment.char <- "#"
                  }
                  tab5rows <- read.table(data, header=header, 
                                         comment.char=comment.char, ..., 
                                         nrows=5)
                  classes <- sapply(tab5rows, class)
                  if(format=="BED"){##check class of column 2 and 3
                      if(classes[2]!="integer"||classes[3]!="integer")
                          stop("No valid data passed in. For example a data frame as 
                               BED format file with at least 3 fields in the order of: 
                               chromosome, start and end. Optional fields are name, score and strand etc.
                               Column 2 and 3 must be integer. 
                               Please refer to http://genome.ucsc.edu/FAQ/FAQformat#format1 for details.")
                      if(!is.na(classes[5])) classes[5] <- "numeric"
                  }else{
                      if(format=="GFF"){##check class of column 4 and 5
                          if(classes[4]!="integer"||classes[5]!="integer")
                              stop("No valid data passed in. 
                                   For example a data frame as
                                   GFF format file with 9 fields in the order of: 
                                   seqname, source, feature, start, end, score, strand, frame and group.
                                   Column 4 and 5 must be integer.
                                   Please refer to http://genome.ucsc.edu/FAQ/FAQformat#format1 for details.")
                      }else{
                          if(format %in% c("MACS", "MACS2")){
                              ## do nothing
                          }else{
                              if(header && is.null(colNames)){ ## format=="others"
                                  colNames <- colnames(tab5rows)
                              }
                          }
                      }
                  }
                  if(format=="BED" && length(classes)>12) 
                      classes[13:length(classes)] <- rep("NULL", length(classes)-12)
                  
                  data <- read.table(data, header=header, 
                                     comment.char=comment.char, ..., 
                                     colClasses=classes)
                  rm(list=c("tab5rows", "classes"))
              }
              colNames <- switchColNames(format, colNames)
              gr <- df2GRanges(data, colNames, format, ...)
              return(gr)
          })