SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_promo_incentive_tracker_0616_sp] @terr VARCHAR(1024) = NULL, @debug INT = 0
AS

-- exec cvo_promo_incentive_tracker_0616_sp NULL, 1

BEGIN

SET NOCOUNT ON

DECLARE @edate DATETIME, @cutoffdate DATETIME -- , @terr VARCHAR(1024)
SELECT @cutoffdate = '05/31/2016 23:59', @edate = '7/1/2016 23:59' --,  @terr = NULL

DECLARE @r12start DATETIME, @r12end DATETIME
SELECT @r12start = begindate, @r12end = enddate
-- SELECT *
FROM dbo.cvo_date_range_vw AS cdrv WHERE period = 'rolling 12 ty'

DECLARE @ytdstartty DATETIME, @ytdendty DATETIME
SELECT @ytdstartty = begindate, @ytdendty = enddate
-- SELECT *
FROM dbo.cvo_date_range_vw AS cdrv WHERE period = 'year to date'

--
SELECT @ytdendty = @edate

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

SELECT @mtdendty = @edate

-- SELECT @ytdendly, @ytdendty, @ytdstartly, @ytdstartty, @mtdendly, @mtdendty, @mtdstartty, @mtdstartly

IF ( OBJECT_ID('tempdb.dbo.#promotrkr') IS NOT NULL )
            DROP TABLE #promotrkr;
IF ( OBJECT_ID('tempdb.dbo.#p') IS NOT NULL )
            DROP TABLE #p;
IF ( OBJECT_ID('tempdb.dbo.#r') IS NOT NULL )
            DROP TABLE #r;
IF ( OBJECT_ID('tempdb.dbo.#f') IS NOT NULL )
            DROP TABLE #f;
IF ( OBJECT_ID('tempdb.dbo.#doorsales') IS NOT NULL )
            DROP TABLE #doorsales;
			
 IF ( OBJECT_ID('tempdb.dbo.#territory') IS NOT NULL )
            DROP TABLE #territory;
        CREATE TABLE #territory
            (
              territory VARCHAR(10) ,
              region VARCHAR(3) ,
			  salesperson_code VARCHAR(10),
              r_id INT ,
              t_id INT IDENTITY(1, 1),
			  ytdtynet FLOAT,
			  ytdlynet FLOAT,
			  mtdtynet FLOAT,
			  mtdlynet FLOAT,
			  TGT INT null
            );

        IF @terr IS NULL
            BEGIN
                INSERT  #territory
						( territory ,
                          region,
						  salesperson_code
                        )
                        SELECT DISTINCT
                                territory_code ,
                                dbo.calculate_region_fn(territory_code) region ,
								salesperson_code
                        FROM    arsalesp
                        WHERE   territory_code IS NOT NULL AND status_type = 1
								AND EXISTS (SELECT 1 FROM armaster ar WHERE ar.territory_code = arsalesp.territory_code AND ar.status_type = 1)
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
								slp.salesperson_code
                        FROM    dbo.f_comma_list_to_table(@terr) t
						JOIN arsalesp slp ON slp.territory_code = t.ListItem AND slp.status_type = 1 -- active
						where EXISTS (SELECT 1 FROM armaster ar WHERE ar.territory_code = slp.territory_code AND ar.status_type = 1)
						AND slp.salesperson_code <> 'smithma'
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


UPDATE t SET ytdtynet = ISNULL( ytdty.net,0),
		     ytdlynet = ISNULL( ytdly.net,0),
			 mtdtynet = ISNULL( mtdty.net,0),
			 mtdlynet = ISNULL( mtdly.net,0),
			 tgt = CASE WHEN tgt.territory_code IS NULL OR t.salesperson_code <> ISNULL(tgt.salesperson_code,'') THEN  1 ELSE 0 end

FROM #territory AS t

LEFT OUTER JOIN 
(SELECT DISTINCT slp.territory_code, slp.salesperson_code
--, ar.salesperson_code, ar.territory_code 
-- , ar.customer_code, ar.ship_to_code
FROM arsalesp slp 
JOIN armaster  ar ON slp.territory_code = ar.territory_code AND ar.status_type = 1
WHERE ((ar.salesperson_code <> slp.salesperson_code AND ar.salesperson_code <> 'smithma') OR 
		(slp.territory_code = slp.salesperson_code) OR -- empty territories
		(slp.salesperson_type = 1))
AND slp.status_type = 1

) tgt ON t.territory = tgt.territory_code -- AND t.salesperson_code <> tgt.salesperson_code

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


IF @debug <> 0  SELECT * FROM #territory AS t

-- get all the doors in all the territories and the r12 net sales

 SELECT t.region, t.territory, t.salesperson_code, door.customer_code,
  door.ship_to_code,
  door.address_name,
  SUM(ANET) AS NET
 INTO #doorsales
 FROM #territory t
 JOIN armaster ar ON ar.territory_code = t.territory
 JOIN cvo_armaster_all car ON car.customer_code = ar.customer_code AND car.ship_to = ar.ship_to_code
 JOIN armaster door ON door.customer_code = ar.customer_code AND door.ship_to_code = CASE WHEN car.door = 1 THEN AR.ship_to_code ELSE '' END
 LEFT OUTER JOIN dbo.cvo_sbm_details AS sbm ON sbm.customer = ar.customer_code AND sbm.ship_to = ar.ship_to_code
 WHERE sbm.yyyymmdd BETWEEN @r12start AND @r12end
 GROUP BY t.region ,
          t.territory ,
          t.salesperson_code ,
          door.customer_code,
		  door.ship_to_code,
		  door.address_name

 IF @debug = 1 SELECT * FROM #doorsales
 		
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
INSERT #p VALUES ('revo','1','11/1/2015','REVO')
INSERT #p VALUES ('revo','2','11/1/2015','REVO')
INSERT #p VALUES ('revo','3','11/1/2015','REVO')
INSERT #p VALUES ('sunps','op','11/1/2015','OP Polarized')
INSERT #p VALUES ('jmc','fs','2/15/2016','JMC Banner')
INSERT #p VALUES ('izod','interchangeable','3/1/2016','IZOD Interchgble')
INSERT #p VALUES ('sun spring','1','5/1/2016','Sun Refresh')
INSERT #p VALUES ('sun spring','2','5/1/2016','Sun Refresh')
INSERT #p VALUES ('izod','t & c','5/1/2016','IZOD T&C')

--SELECT * FROM dbo.CVO_promotions
--JOIN #p on #p.promo_id = CVO_promotions.promo_id AND #p.promo_level = CVO_promotions.promo_level

-- tally promo activity

SELECT distinct
o.order_no, o.ext, o.total_amt_order, o.total_invoice, o.orig_no, o.orig_ext, 
t.territory, o.cust_code, 
 o.ship_to ,
o.promo_id, o.promo_level, o.order_type, 
o.back_ord_flag, cast('1/1/1900' as datetime) as return_date,
space(40) as reason,
cast(0.00 as decimal(20,8)) as return_amt,
source = CASE WHEN o.date_entered > @cutoffdate THEN 'N' ELSE o.source end
, qual_order = 0
, #p.Program

into #promotrkr

FROM  #territory t 
INNER join cvo_adord_vw AS o WITH (nolock) on t.territory = o.territory
INNER JOIN #p ON #p.promo_id = o.promo_id AND #p.promo_level = o.promo_level
WHERE 1=1
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

-- update the info for an order prior to the cutoff.
update t set 
t.return_date = #r.return_date,
t.reason = #r.reason
from #r , #promotrkr t where #r.order_no = t.order_no and #r.ext = t.ext
AND #r.return_date < @cutoffdate

INSERT #promotrkr
        ( order_no ,
          ext ,
          territory ,
          cust_code ,
          ship_to ,
          Program,
		  source,
		  qual_order
        )
SELECT r.order_no ,
       r.ext ,
       p.territory,
	   p.cust_code,
	   p.ship_to,
	   p.Program,
	   'R',
	   -1
	   FROM #r AS r
	   JOIN #promotrkr AS p ON p.order_no = r.order_no AND p.ext = r.ext
	WHERE r.return_date >= @cutoffdate
 
UPDATE t SET qual_order =  case when source = 'A' then 0 
WHEN source = 'R' THEN -1 -- if it was returned but after the cut-off.  take it away from programs written (n)
when isnull(reason,'') = '' 
	AND not exists (select 1 from cvo_promo_override_audit poa where poa.order_no = t.order_no and poa.order_ext = t.ext) 
	THEN 1 
else 0 END
FROM #promotrkr t

-- mark the non-door ship-to's so we can roll them up into the master account
UPDATE t SET ship_to = ''
FROM #promotrkr t
INNER JOIN cvo_armaster_all car ON car.ship_to = t.ship_to AND car.customer_code = t.cust_code
WHERE car.door = 0 AND t.ship_to <> ''

SELECT DISTINCT p.order_no ,
       p.ext ,
	   t.region,
       t.territory ,
	   t.salesperson_code,
       ar.customer_code cust_code ,
       ar.ship_to_code ship_to ,
	   ar.address_name,
	   CAST(0 AS FLOAT) AS r12net,
	   -- ISNULL(r12.net,0) r12net,
	   t.ytdtynet,
	   t.ytdlynet,
	   t.mtdtynet,
	   t.mtdlynet,
       ISNULL(p.source,'A') source ,
       ISNULL(p.qual_order,0) qual_order ,
	   p.program,
	   ROW_NUMBER() OVER (PARTITION BY ar.customer_code, ar.ship_to_code ORDER BY ar.customer_code, ar.ship_to_code) rank_cust

	   INTO #f

	   FROM 
#promotrkr p 
LEFT OUTER JOIN armaster ar ON ar.customer_code = p.cust_code AND ar.ship_to_code = p.ship_to
LEFT OUTER JOIN #territory AS t ON t.territory = p.territory

-- fill in the blanks

-- JOIN #territory AS t ON t.territory = p.territory
INSERT INTO #f (region, territory, salesperson_code, program, source, r12net, qual_order, ytdtynet,
	   ytdlynet,
	   mtdtynet,
	   mtdlynet)
	SELECT DISTINCT t.region, t.territory, slp.salesperson_code
		, #p.program, 'A' AS source, 0 AS r12net, 0 AS qual_order,
	   t.ytdtynet,
	   t.ytdlynet,
	   t.mtdtynet,
	   t.mtdlynet
		FROM #p CROSS JOIN #territory t 
		LEFT OUTER JOIN arsalesp slp ON slp.territory_code = t.territory AND slp.status_type = 1
		WHERE region < '800'

 --UPDATE f SET r12net = r12.net
 --FROM #f f 
 --LEFT OUTER JOIN
 --(SELECT car.customer_code, 
 --CASE WHEN car.door = 1 THEN car.ship_to ELSE '' END AS ship_to,
 --SUM(anet) net
 --FROM dbo.cvo_sbm_details AS sbm
 --JOIN cvo_armaster_all car ON sbm.customer = car.customer_code AND sbm.ship_to = car.ship_to
 --WHERE yyyymmdd BETWEEN @r12start AND @r12end
 --GROUP BY CASE WHEN car.door = 1 THEN car.ship_to
 --         ELSE ''
 --         END ,
 --         car.customer_code
 --) r12 ON r12.ship_to = f.ship_to AND r12.customer_code = f.cust_code
 --WHERE f.rank_cust = 1

 INSERT INTO #f(region, territory, salesperson_code, cust_code, ship_to, address_name, source, r12net, qual_order
 , ytdtynet,
	   ytdlynet,
	   mtdtynet,
	   mtdlynet)
 SELECT DISTINCT d.region, d.territory, d.salesperson_code, d.customer_code, d.ship_to_code, d.address_name, 'A', SUM(ISNULL(d.net,0)) r12net, 0 AS qual_order
 , t.ytdtynet,
   t.ytdlynet,
   t.mtdtynet,
   t.mtdlynet
 FROM #doorsales d
 JOIN #territory AS t ON t.territory = d.territory
 -- WHERE NOT EXISTS (SELECT 1 FROM #f WHERE #f.cust_code = d.customer_code AND #f.ship_to = d.ship_to_code)
 GROUP BY d.region ,
          d.territory ,
          d.salesperson_code ,
          d.customer_code ,
          d.ship_to_code ,
          d.address_name ,
          d.net ,
          t.ytdtynet ,
          t.ytdlynet ,
          t.mtdtynet ,
          t.mtdlynet

SELECT DISTINCT #f.order_no ,
       #f.ext ,
       #f.region ,
       #f.territory ,
       #f.salesperson_code ,
       #f.cust_code ,
       #f.ship_to ,
       #f.address_name ,
       #f.r12net ,
       #f.ytdtynet ,
       #f.ytdlynet ,
       #f.mtdtynet ,
       #f.mtdlynet ,
       #f.source ,
       #f.qual_order ,
       #f.Program 
	   ,t.TGT
	   , @cutoffdate cutoffdate

	   FROM #f
	   LEFT OUTER JOIN #territory AS t ON t.territory = #f.territory




END




GO
GRANT EXECUTE ON  [dbo].[cvo_promo_incentive_tracker_0616_sp] TO [public]
GO
