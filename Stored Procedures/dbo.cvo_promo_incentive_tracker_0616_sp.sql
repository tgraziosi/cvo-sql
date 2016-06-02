SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_promo_incentive_tracker_0616_sp] @terr VARCHAR(1024) = NULL
AS

-- exec cvo_promo_incentive_tracker_0616_sp '20201'

BEGIN

SET NOCOUNT ON

DECLARE @edate DATETIME, @cutoffdate DATETIME -- , @terr VARCHAR(1024)
SELECT @cutoffdate = '05/31/2016 23:59', @edate = '7/1/2016' --,  @terr = NULL

DECLARE @r12start DATETIME, @r12end DATETIME
SELECT @r12start = begindate, @r12end = enddate
-- SELECT *
FROM dbo.cvo_date_range_vw AS cdrv WHERE period = 'rolling 12 ty'

DECLARE @ytdstartty DATETIME, @ytdendty DATETIME
SELECT @ytdstartty = begindate, @ytdendty = enddate
-- SELECT *
FROM dbo.cvo_date_range_vw AS cdrv WHERE period = 'year to date'

DECLARE @ytdstartly DATETIME, @ytdendly DATETIME
SELECT @ytdstartly = DATEADD(YEAR, -1, @ytdstartty),
	   @ytdendly = DATEADD(YEAR, -1, @ytdendty)

DECLARE @mtdstartty DATETIME, @mtdendty DATETIME,
		@mtdstartly DATETIME, @mtdendly datetime
SELECT @mtdstartty = begindate, @mtdendty = enddate,
	   @mtdstartly = DATEADD(YEAR, - 1, begindate),
	   @mtdendly = DATEADD(YEAR, -1, enddate)
-- SELECT *
FROM dbo.cvo_date_range_vw AS cdrv WHERE period = 'month to date'

-- SELECT @ytdendly, @ytdendty, @ytdstartly, @ytdstartty, @mtdendly, @mtdendty, @mtdstartty, @mtdstartly

IF ( OBJECT_ID('tempdb.dbo.#promotrkr') IS NOT NULL )
            DROP TABLE #promotrkr;
IF ( OBJECT_ID('tempdb.dbo.#p') IS NOT NULL )
            DROP TABLE #p;
IF ( OBJECT_ID('tempdb.dbo.#r') IS NOT NULL )
            DROP TABLE #r;
IF ( OBJECT_ID('tempdb.dbo.#f') IS NOT NULL )
            DROP TABLE #f;

 IF ( OBJECT_ID('tempdb.dbo.#territory') IS NOT NULL )
            DROP TABLE #territory;
        CREATE TABLE #territory
            (
              territory VARCHAR(10) ,
              region VARCHAR(3) ,
			  salesperson_code VARCHAR(10),
              r_id INT ,
              t_id INT IDENTITY(1, 1)
            );

        IF @terr IS NULL
            BEGIN
                INSERT  #territory
                        SELECT DISTINCT
                                territory_code ,
                                dbo.calculate_region_fn(territory_code) region ,
								salesperson_code,
                                0
                        FROM    arsalesp
                        WHERE   territory_code IS NOT NULL AND status_type = 1
                        ORDER BY territory_code;
            END;
        ELSE
            BEGIN
                INSERT  INTO #territory
                        ( territory ,
                          region,
						  salesperson_code
                        )
                        SELECT DISTINCT
                                ListItem ,
                                dbo.calculate_region_fn(ListItem) region,
								ar.salesperson_code
                        FROM    dbo.f_comma_list_to_table(@terr) t
						LEFT OUTER JOIN arsalesp ar ON ar.territory_code = t.ListItem AND ar.status_type = 1
                        ORDER BY ListItem;
            END;


			-- SELECT * FROM dbo.arsalesp AS a

        UPDATE  t
        SET     t.r_id = r.r_id
-- SELECT * 
        FROM    #territory AS t
                JOIN ( SELECT DISTINCT
                                region ,
                                RANK() OVER ( ORDER BY region ) r_id
                       FROM     ( SELECT DISTINCT
                                            region
                                  FROM      #territory
                                ) AS r
                     ) AS r ON t.region = r.region;

-- SELECT * FROM #territory AS t
			
CREATE TABLE #p (promo_id VARCHAR(30), 
				 promo_level VARCHAR(30),
				 sdate DATETIME,
				 Program VARCHAR(30))

INSERT #p VALUES ('aspire','launch','1/1/2015','Aspire')
INSERT #p VALUES ('aspire','1','1/1/2015','Aspire')
INSERT #p VALUES ('aspire','new','1/1/2015','Aspire')
INSERT #p VALUES ('aspire','3','1/1/2015','Aspire')
INSERT #p VALUES ('aspire','vew','1/1/2015','Aspire')
INSERT #p VALUES ('revo','launch 1','11/1/2015','REVO')
INSERT #p VALUES ('revo','launch 2','11/1/2015','REVO')
INSERT #p VALUES ('revo','launch 3','11/1/2015','REVO')
INSERT #p VALUES ('sunps','op','11/1/2015','OP Polarized')
INSERT #p VALUES ('jmc','fs','2/15/2016','JMC Banner')
INSERT #p VALUES ('izod','interchangeable','3/1/2016','IZOD Interchgble')
INSERT #p VALUES ('sun spring','1','5/1/2016','Sun Refresh')
INSERT #p VALUES ('sun spring','2','5/1/2016','Sun Refresh')
INSERT #p VALUES ('izod','t & c','5/1/2016','IZOD T&C')

--SELECT * FROM dbo.CVO_promotions
--JOIN #p on #p.promo_id = CVO_promotions.promo_id AND #p.promo_level = CVO_promotions.promo_level

-- tally promo activity

SELECT 
o.order_no, o.ext, o.total_amt_order, o.total_invoice, o.orig_no, o.orig_ext, 
t.territory, o.cust_code, o.ship_to,
o.promo_id, o.promo_level, o.order_type, 
o.FramesOrdered, o.FramesShipped, o.back_ord_flag, o.Cust_type, 
cast('1/1/1900' as datetime) as return_date,
space(40) as reason,
cast(0.00 as decimal(20,8)) as return_amt,
0 as return_qty,
source = CASE WHEN o.date_entered > @cutoffdate THEN 'N' ELSE o.source end
, qual_order = 0
, uc = 0
, ROW_NUMBER() OVER(PARTITION BY o.cust_code ORDER BY o.cust_code ASC , o.ship_to ASC) cust_rank

into #promotrkr

FROM  #territory t 
INNER join cvo_adord_vw AS o WITH (nolock) on t.territory = o.territory
INNER JOIN #p ON #p.promo_id = o.promo_id AND #p.promo_level = o.promo_level
where 1=1
AND o.date_entered BETWEEN #p.sdate AND @edate
AND o.who_entered <> 'backordr' -- 1/18/2016
and o.status <> 'V' -- 110714 - exclude void orders

-- SELECT * FROM #promotrkr AS p

-- Collect the returns

select o.orig_no order_no, o.orig_ext ext,
	return_date = o.date_entered, 
	reason = min(rc.return_desc)
into #r
from #promotrkr t inner join  orders o (nolock) on t.order_no = o.orig_no and t.ext = o.orig_ext
 inner join ord_list ol (nolock) on   ol.order_no = o.order_no and ol.order_ext = o.ext
 INNER JOIN inv_master i(nolock) ON ol.part_no = i.part_no 
 INNER JOIN po_retcode rc(nolock) ON ol.return_code = rc.return_code
 WHERE 1=1
 -- and LEFT(ol.return_code, 2) <> '05' -- AND i.type_code = 'sun'
  AND o.status = 't' and o.type = 'c' 
  and (o.total_invoice = t.total_invoice or o.total_amt_order = t.total_amt_order)
group by o.orig_no, o.orig_ext, o.date_entered, o.total_amt_order -- o.total_invoice


update t set 
t.return_date = #r.return_date,
t.reason = #r.reason
from #r , #promotrkr t where #r.order_no = t.order_no and #r.ext = t.ext

--select * from #r
--select * From #promotrkr

update t set uc = 1
	from 
	(select cust_code, promo_id, min(order_no) min_order from #promotrkr 
		inner join cvo_armaster_all car (nolock) on car.customer_code = #promotrkr.cust_code
			and car.ship_to = #promotrkr.ship_to
		where source <> 'T' and (isnull(reason,'') = '' 
		and not exists (select 1 from cvo_promo_override_audit poa 
			where poa.order_no = #promotrkr.order_no and poa.order_ext = #promotrkr.ext))
		and car.door = 1
		group by cust_code, promo_id
	) as m 	inner join #promotrkr t 
	on t.cust_code = m.cust_code and t.promo_id = m.promo_id and t.order_no = m.min_order
 
UPDATE t SET qual_order =  case when source = 'T' then 0 
when isnull(reason,'') = '' and not exists (select 1 from cvo_promo_override_audit poa where poa.order_no = t.order_no and poa.order_ext = t.ext) then 1 
else 0 END
FROM #promotrkr t




SELECT p.order_no ,
       p.ext ,
       p.total_amt_order ,
       p.total_invoice ,
       p.orig_no ,
       p.orig_ext ,
	   t.region,
       t.territory ,
	   ISNULL(ar.salesperson_code,t.salesperson_code) salesperson_code,
       ar.customer_code cust_code ,
       ar.ship_to_code ship_to ,
	   ar.address_name,
	   0 AS r12net,
	   -- ISNULL(r12.net,0) r12net,
	   ytdty.net ytdtynet,
	   ytdly.net ytdlynet,
	   mtdty.net mtdtynet,
	   mtdly.net mtdlynet,
       p.promo_id ,
       p.promo_level ,
       p.order_type ,
       p.FramesOrdered ,
       p.FramesShipped ,
       p.back_ord_flag ,
       p.Cust_type ,
       p.return_date ,
       p.reason ,
       p.return_amt ,
       p.return_qty ,
       ISNULL(p.source,'A') source ,
       ISNULL(p.qual_order,0) qual_order ,
       ISNULL(p.uc,0) uc ,
	   t.program,
	   ROW_NUMBER() OVER (PARTITION BY ar.customer_code, ar.ship_to_code ORDER BY ar.customer_code, ar.ship_to_code) rank_cust

	   INTO #f

	   FROM 

(SELECT DISTINCT #p.*,#territory.*
FROM 
#p CROSS JOIN #territory
WHERE region < '800'
) AS t
LEFT OUTER JOIN armaster ar ON ar.territory_code = t.territory
LEFT OUTER JOIN #promotrkr p ON p.cust_code = ar.customer_code AND p.ship_to = ar.ship_to_code AND p.promo_id = t.promo_id
	AND p.promo_level = t.promo_level

-- JOIN #territory AS t ON t.territory = p.territory


LEFT OUTER JOIN
(SELECT tt.territory, SUM(anet) net
 FROM #territory AS tt 
 JOIN armaster ar ON ar.territory_code = tt.territory
 JOIN dbo.cvo_sbm_details AS sbm ON ar.customer_code = sbm.customer AND ar.ship_to_code = sbm.ship_to
 WHERE yyyymmdd BETWEEN @ytdstartty AND @ytdendty
 GROUP BY tt.territory
) ytdty ON ytdty.territory = t.territory
LEFT OUTER JOIN
(SELECT tt.territory, SUM(anet) net
 FROM #territory AS tt 
 JOIN armaster ar ON ar.territory_code = tt.territory
 JOIN dbo.cvo_sbm_details AS sbm ON ar.customer_code = sbm.customer AND ar.ship_to_code = sbm.ship_to
 WHERE yyyymmdd BETWEEN @ytdstartly AND @ytdendly
 GROUP BY tt.territory
) ytdly ON ytdly.territory = t.territory

LEFT OUTER JOIN
(SELECT tt.territory, SUM(anet) net
 FROM #territory AS tt 
 JOIN armaster ar ON ar.territory_code = tt.territory
 JOIN dbo.cvo_sbm_details AS sbm ON ar.customer_code = sbm.customer AND ar.ship_to_code = sbm.ship_to
 WHERE yyyymmdd BETWEEN @mtdstartty AND @mtdendty
 GROUP BY tt.territory
) mtdty ON mtdty.territory = t.territory

LEFT OUTER JOIN
(SELECT tt.territory, SUM(anet) net
 FROM #territory AS tt 
 JOIN armaster ar ON ar.territory_code = tt.territory
 JOIN dbo.cvo_sbm_details AS sbm ON ar.customer_code = sbm.customer AND ar.ship_to_code = sbm.ship_to
 WHERE yyyymmdd BETWEEN @mtdstartly AND @mtdendly
 GROUP BY tt.territory
) mtdly ON mtdly.territory = t.territory

 
SELECT #f.order_no ,
       #f.ext ,
       #f.total_amt_order ,
       #f.total_invoice ,
       #f.orig_no ,
       #f.orig_ext ,
       #f.region ,
       #f.territory ,
       #f.salesperson_code ,
       #f.cust_code ,
       #f.ship_to ,
       #f.address_name ,
       CASE WHEN #f.rank_cust = 1 THEN ISNULL(r12.net,0) ELSE 0 END AS r12net ,
       #f.ytdtynet ,
       #f.ytdlynet ,
       #f.mtdtynet ,
       #f.mtdlynet ,
       #f.promo_id ,
       #f.promo_level ,
       #f.order_type ,
       #f.FramesOrdered ,
       #f.FramesShipped ,
       #f.back_ord_flag ,
       #f.Cust_type ,
       #f.return_date ,
       #f.reason ,
       #f.return_amt ,
       #f.return_qty ,
       #f.source ,
       #f.qual_order ,
       #f.uc ,
       #f.Program ,
       #f.rank_cust
	   FROM #f
LEFT OUTER JOIN 
(SELECT sbm.customer, sbm.ship_to, SUM(anet) net
 FROM dbo.cvo_sbm_details AS sbm
 WHERE yyyymmdd BETWEEN @r12start AND @r12end
 GROUP BY sbm.customer, sbm.ship_to
) r12 ON r12.customer = #f.cust_code AND r12.ship_to = #f.ship_to



END
GO
GRANT EXECUTE ON  [dbo].[cvo_promo_incentive_tracker_0616_sp] TO [public]
GO
