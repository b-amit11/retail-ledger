-- Compare only fully observed months. December 2011 ends on the 9th.
WITH previous AS (
 SELECT month,net_gbp,LAG(net_gbp) OVER(ORDER BY month) AS previous_net
 FROM monthly WHERE complete_month=1
)
SELECT month,net_gbp,previous_net,
 CASE WHEN previous_net IS NULL OR previous_net=0 THEN NULL
 ELSE (net_gbp-previous_net)/previous_net END AS net_change_rate
FROM previous ORDER BY month;
