# No packages required: base R analysis, charts, and a standalone HTML dashboard.
args <- commandArgs(trailingOnly=TRUE)
root <- if(length(args)) args[1] else '.'
m <- read.csv(file.path(root,'exports/monthly.csv'))
countries <- read.csv(file.path(root,'exports/countries.csv'))
cohorts <- read.csv(file.path(root,'exports/cohorts.csv'))
stopifnot(all(abs(m$gross_gbp-m$cancellations_gbp-m$net_gbp)<0.001))
full <- m[m$complete_month==1,]
full$cancellation_value_rate <- full$cancellations_gbp/full$gross_gbp
full$net_change_pct <- c(NA,diff(full$net_gbp)/head(full$net_gbp,-1))
write.csv(full,file.path(root,'exports/r_monthly_analysis.csv'),row.names=FALSE,na='')
# Monthly net movement, explicitly excluding incomplete December 2011.
svg(file.path(root,'reports/monthly.svg'),width=10,height=4.5)
par(mar=c(5,5,3,1));plot(seq_len(nrow(full)),full$net_gbp/1e6,type='b',pch=19,col='#255B81',xaxt='n',xlab='',ylab='Net transaction value (GBP millions)',main='Complete months only')
axis(1,at=seq_len(nrow(full)),labels=full$month,las=2,cex.axis=.8);grid();dev.off()
svg(file.path(root,'reports/countries.svg'),width=10,height=4.5)
nonuk <- head(countries[countries$country!='United Kingdom',],8)
par(mar=c(5,9,3,1));barplot(rev(nonuk$net_gbp)/1000,names.arg=rev(nonuk$country),horiz=TRUE,las=1,col='#38877A',border=NA,xlab='Net transaction value (GBP thousands)',main='Largest markets outside the UK');dev.off()
cs <- sort(unique(cohorts$cohort)); mat <- matrix(NA,nrow=length(cs),ncol=12)
for(i in seq_len(nrow(cohorts)))mat[match(cohorts$cohort[i],cs),cohorts$month_index[i]+1] <- cohorts$retention[i]
# Observed-but-empty months are 0; future unobserved months stay NA.
for(i in seq_along(cs))for(j in 1:(length(cs)-i+1))if(is.na(mat[i,j]))mat[i,j]<-0
svg(file.path(root,'reports/retention.svg'),width=10,height=5.5)
par(mar=c(4,6,3,1));image(0:11,seq_along(cs),t(mat),col=colorRampPalette(c('#F2F6FA','#245D82'))(100),zlim=c(0,1),axes=FALSE,xlab='Months since first observed purchase',ylab='',main='Identified-customer cohort retention')
axis(1,at=0:11);axis(2,at=seq_along(cs),labels=cs,las=1,cex.axis=.8)
for(i in seq_along(cs))for(j in 1:12)if(!is.na(mat[i,j]))text(j-1,i,sprintf('%.0f%%',100*mat[i,j]),cex=.65,col=if(mat[i,j]>.55)'white' else '#172B3A')
dev.off()
fmt <- function(x)format(round(x,2),big.mark=',',nsmall=2)
gross<-sum(m$gross_gbp);cancel<-sum(m$cancellations_gbp);net<-sum(m$net_gbp)
ukshare<-countries$net_gbp[countries$country=='United Kingdom']/net
notes<-c(sprintf('Recorded gross sales GBP %s less cancellation value GBP %s equals net transaction value GBP %s.',fmt(gross),fmt(cancel),fmt(net)),sprintf('Cancellation value is %.2f%% of gross sales. It is not an item-return rate: cancellations are not matched to original purchases.',100*cancel/gross),sprintf('The UK accounts for %.1f%% of net transaction value. Review international markets separately so the UK does not hide differences.',100*ukshare),'December 2011 stops on the 9th and is excluded from trend and cohort comparisons.','Cohorts begin at first observed purchase, not proven first-ever purchase. Customers without IDs are excluded from retention, but remain in transaction totals.')
writeLines(notes,file.path(root,'reports/findings.txt'))
svgtext<-function(name){
 text<-paste(readLines(file.path(root,paste0('reports/',name,'.svg')),warn=FALSE),collapse='\n')
 text<-gsub('id="',paste0('id="',name,'_'),text,fixed=TRUE)
 text<-gsub('href="#',paste0('href="#',name,'_'),text,fixed=TRUE)
 gsub('url(#',paste0('url(#',name,'_'),text,fixed=TRUE)
}
# Generated HTML contains data and inline SVGs; no runtime or internet is needed to view it.
html<-paste0('<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Retail Ledger</title><style>body{font:16px system-ui;background:#f4f7fa;color:#173047;margin:0}main{max-width:1100px;margin:auto;padding:35px}h1{font-size:36px}section{background:white;padding:24px;margin:20px 0;border-radius:12px}svg{width:100%;height:auto}button{padding:10px 18px;margin:4px;border:1px solid #255b81;background:white;color:#255b81;cursor:pointer}li{margin:10px 0}.panel{display:none}.panel.active{display:block}</style></head><body><main><h1>Retail Ledger</h1><p>Sales, cancellations and observed customer retention · December 2010–December 2011 · GBP</p><section><h2>Findings</h2><ul>',paste0('<li>',notes,'</li>',collapse=''),'</ul></section><nav><button onclick="show(0)">Monthly trend</button><button onclick="show(1)">Markets</button><button onclick="show(2)">Retention</button></nav><section class="panel active">',svgtext('monthly'),'</section><section class="panel">',svgtext('countries'),'</section><section class="panel">',svgtext('retention'),'<p>White cells are unobserved periods, not zero retention.</p></section><section><h2>Method and source</h2><p>SQL classifies transactions and aggregates source records. R calculates monthly changes and renders these charts. Exact duplicate rows are excluded as an explicit assumption. Nonpositive prices and non-cancellation negative adjustments are excluded from sales metrics and retained in the audit.</p><p>No cost, payment settlement, acquisition spend, or cancellation reason is available. This is not profit, realized cash, or causal marketing analysis.</p><a href="https://archive.ics.uci.edu/dataset/352/online-retail">Chen (2015), UCI Online Retail, CC BY 4.0</a></section></main><script>function show(n){document.querySelectorAll(".panel").forEach((p,i)=>p.classList.toggle("active",i===n))}</script></body></html>')
writeLines(html,file.path(root,'reports/dashboard.html'))
cat(paste(notes,collapse='\n'),'\n')
