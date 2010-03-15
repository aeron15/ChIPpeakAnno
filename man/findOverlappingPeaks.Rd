\name{findOverlappingPeaks}
\alias{findOverlappingPeaks}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Find the overlapping peaks for two peak ranges.
}
\description{
Find the overlapping peaks for two input peak ranges.
}
\usage{
findOverlappingPeaks(Peaks1, Peaks2, maxgap = 100, multiple = c(TRUE, FALSE), NameOfPeaks1 = "TF1", NameOfPeaks2 = "TF2")
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{Peaks1}{
RangedData: See example below.
}
  \item{Peaks2}{
RangedData: See example below.
}
  \item{maxgap}{
Non-negative integer. Intervals with a separation of maxgap or less are considered to be overlapping.
}
  \item{multiple}{
TRUE or FALSE: TRUE may return multiple overlapping peaks in Peaks2 for one peak in Peaks1; FALSE will return at most one overlapping peaks in Peaks2 for one peak in Peaks1.
}
  \item{NameOfPeaks1}{
Name of the Peaks1, used for generating column name.
}
  \item{NameOfPeaks2}{
Name of the Peaks2, used for generating column name.
}
}
\details{
Efficiently perform overlap queries with an interval tree implemented in IRanges.
}
\value{
  \item{OverlappingPeaks}{a data frame consists of input peaks information with added information: overlapFeature (upstream: peak1 resides upstream of the peak2; downstream: peak1 resides downstream of the peak2; inside: peak1 resides inside the peak2 entirely; overlapStart: peak1 overlaps with the start of the peak2; overlapEnd: peak1 overlaps with the end of the peak2; includeFeature: peak1 include the peak2 entirely) and shortestDistance (shortest distance between the overlapping peaks}
  \item{MergedPeaks}{RangedData contains merged overlapping peaks}
}
\references{
Interval tree algorithm from: Cormen, Thomas H.; Leiserson, Charles E.; Rivest, Ronald L.; Stein, Clifford. Introduction to Algorithms, second edition, MIT Press and McGraw-Hill. ISBN 0-262-53196-8
}
\author{
Lihua Julie Zhu
}
\note{

}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
	annotatePeakInBatch, makeVennDiagram
}
\examples{
	if (interactive())
	{	
	peaks1 = RangedData(IRanges(start=c(1543200,1557200,1563000,1569800,167889600),end=c(1555199,1560599,1565199,1573799,167893599),names=c("p1","p2","p3","p4","p5")),strand=as.integer(1),space=c(6,6,6,6,5))
	t1 =findOverlappingPeaks(peaks1, peaks2, maxgap=1000, multiple=F) 
	r = t1$OverlappingPeaks
	pie(table(r$overlapFeature))
	as.data.frame(t1$MergedPeaks)
	}
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ misc }