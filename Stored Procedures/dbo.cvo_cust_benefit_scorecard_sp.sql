SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_cust_benefit_scorecard_sp]
	@cust VARCHAR(10) = NULL, @date VARCHAR(100) = NULL

AS
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

-- exec cvo_cust_benefit_scorecard_sp '011111'

-- DECLARE @cust VARCHAR(10), @date VARCHAR(100)

DECLARE @enddate DATETIME, @startdate datetime
-- SELECT @cust = NULL -- '011111' -- everyone
IF @date IS NULL SELECT @date = 'Rolling 12 TY'
SELECT @enddate = enddate,
	   @startdate = begindate FROM cvo_date_range_vw WHERE period = @date

IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t

IF(OBJECT_ID('tempdb.dbo.#narrative') is not null)  drop table #narrative
CREATE TABLE #narrative
	( seq INT IDENTITY (1,1),
	  cust_code VARCHAR(10),
	  ship_to VARCHAR(8),
	  ben_type VARCHAR(60),
	  ben_title VARCHAR(60),
	  val_1_lbl VARCHAR(60),
	  val_1_int	integer,
	  val_2_lbl VARCHAR(60),
	  val_2_int integer,
	  val_3_lbl VARCHAR(60),
	  val_3_dec DECIMAL(20,8),
	  val_4_lbl VARCHAR(60), 
	  val_4_dec DECIMAL(20,8)
	)

-- customer name records for all
INSERT INTO #narrative (cust_code, ship_to, ben_type, ben_title, val_3_dec )
SELECT DISTINCT t.cust_code, t.ship_to, 'Customer Name', t.address_name, SUM(ISNULL(sbm.anet,0))
FROM 
(SELECT DISTINCT ar.customer_code cust_code
, CASE WHEN ar.status_type = 1 THEN ar.ship_to_code ELSE '' END AS ship_to
, CASE when ar.address_type = 0 AND ar.status_type = 1 THEN cust.customer_name 
	   WHEN ar.address_type = 1 AND ar.status_type = 1 THEN ar.address_name 
	   ELSE cust.customer_name 
	   END AS address_name
FROM armaster ar (NOLOCK)
JOIN arcust cust (NOLOCK) ON cust.customer_code = ar.customer_code
JOIN cvo_armaster_all car (nolock) 
	ON car.customer_code = ar.customer_code AND car.ship_to = ar.ship_to_code
WHERE ar.customer_code = ISNULL(@cust,ar.customer_code)
) AS t
LEFT OUTER JOIN cvo_sbm_details sbm
ON sbm.customer = t.cust_code AND sbm.ship_to = t.ship_to
WHERE ISNULL(yyyymmdd,@enddate) BETWEEN @startdate AND @enddate
GROUP BY t.cust_code ,
         t.ship_to ,
         t.address_name

UPDATE #narrative SET val_3_lbl = '12 Mth Net Sales ending '+CONVERT(VARCHAR(10),@enddate,101) WHERE ben_type = 'Customer Name'


-- promo benefits
SELECT ar.customer_code cust_code
, CASE WHEN ar.status_type = 1 THEN ar.ship_to_code ELSE '' END AS ship_to
, ar.address_name
, CAST(i.category AS VARCHAR(50)) Coll
-- , o.promo_level
, SUM(CASE WHEN o.free_frame = 1 THEN o.shipped ELSE 0 END) free_frames
, SUM(CASE WHEN o.free_frame = 0 THEN o.shipped ELSE 0 END) full_price_frames
, SUM(CASE WHEN o.free_frame = 1 THEN o.shipped * o.Orig_List_price ELSE 0 end) extprice
--, SUM(CASE WHEN o.promo_id = 'pc' THEN o.shipped ELSE 0 END) pc_frames
--, SUM(CASE WHEN o.promo_id = 'style out' THEN o.shipped ELSE 0 END) style_out_frames

INTO #t
FROM armaster ar (NOLOCK) 
LEFT OUTER JOIN dbo.cvo_item_pricing_analysis o (NOLOCK) ON o.cust_code = ar.customer_code AND o.ship_to = ar.ship_to_code
JOIN inv_master i (NOLOCK) ON i.part_no = o.part_no
WHERE i.type_code IN ('frame','sun')
AND ISNULL(o.promo_id,'') NOT IN ('pc','style out')
AND ISNULL(o.date_entered,@startdate) BETWEEN  @startdate AND @enddate
-- AND ISNULL(o.promo_id,'') <> ''
AND ar.customer_code = ISNULL(@cust,ar.customer_code)
 
GROUP BY ar.customer_code, CASE WHEN ar.status_type = 1 THEN ar.ship_to_code ELSE '' END, ar.address_name, CAST(i.category AS VARCHAR(50)) 



insert into #narrative (cust_code, ship_to, ben_type, ben_title, val_1_lbl, val_1_int, val_2_lbl, val_2_int, val_3_lbl, val_3_dec)
SELECT  cust_code
, ship_to
, ben_type = 'Promotional Frame Benefit'
-- , ben_title = p.promo_name
, ben_title = p.description
, val_1_lbl = 'Free Frames'
, val_1_int = SUM(free_frames)
, val_2_lbl = 'Full Price Frames'
, val_2_int = SUM(full_price_frames)
, val_3_lbl = 'Value of Free Frames'
, val_3_dec = SUM(extprice)
--, sentence = 'Promotional Frame Benefit : ' + CAST(promo_id AS VARCHAR(50))
--	+ ' Free Frames: ' + CAST(CAST(free_frames AS INTEGER) AS VARCHAR(20))
--	+ ' Full Price Frames: ' + CAST(CAST(full_price_frames AS INTEGER) AS varchar(20))
--	+ ' Total Net Price: ' + cast(CAST(ExtPrice AS DECIMAL(10,2)) AS VARCHAR(20))
from #t
-- LEFT OUTER JOIN cvo_promotions p ON p.promo_id = #t.promo_id AND p.promo_level = #t.promo_level
LEFT OUTER JOIN dbo.category AS p ON p.kys = #t.coll
WHERE #t.free_frames <> 0
GROUP BY cust_code, ship_to, p.description

UPDATE n SET n.val_1_lbl = '', n.val_2_lbl = '', n.val_3_lbl = '', n.val_4_lbl = ''
-- SELECT * 
FROM #narrative AS n
JOIN 
(SELECT cust_code, ship_to, MIN(seq) seq
FROM #narrative AS n2 
WHERE ben_type = 'Promotional Frame Benefit' AND val_1_lbl = 'Free Frames'
GROUP BY n2.cust_code, n2.ship_to
) AS min_seq ON min_seq.cust_code = n.cust_code AND min_seq.ship_to = n.ship_to
WHERE min_seq.seq <> n.seq
AND ben_Type = 'Promotional Frame Benefit' AND val_1_lbl = 'Free Frames'


insert into #narrative (cust_code, ship_to, ben_type, ben_title, val_1_lbl, val_1_int, val_3_lbl, val_3_dec)
SELECT cust_code, ship_to
, ben_type = 'Promotional Frame Benefit'
, ben_title = 'Total Savings'
, val_1_lbl = 'Free Frames'
, val_1_int = CAST(SUM(free_frames) AS INTEGER)
, val_3_lbl = 'Total Value of Free Frames'
, val_3_dec = CAST(ROUND(SUM(extprice) ,2) AS DECIMAL(10,2))
--, sentence = 
--'Free Frame Benefit:  Total Savings: '
--+ CAST(CAST(SUM(free_frames) AS INTEGER) AS varchar(15)) 
--+ ' Frames @ $50 AVG Cost = ' 
--+ CAST(CAST(SUM(free_frames)*50 AS DECIMAL(10,2)) as varchar(15)) 
FROM #t
GROUP BY cust_code, ship_to

INSERT #narrative (cust_code, ship_to, ben_type, ben_title, val_1_int)
SELECT ar.customer_code cust_code
, CASE WHEN ar.status_type = 1 THEN ar.ship_to_code ELSE '' END AS ship_to
, ben_type = 'Free Frame Benefit'
, ben_title = 'PC and Style Out Frames'
, val_1_int = CAST(SUM(o.shipped) AS INTEGER)
--, sentence = 
--'PC and Style Out Frames received: ' + CAST(CAST(SUM(o.shipped) AS INTEGER) AS VARCHAR(10))
FROM armaster ar (NOLOCK) 
LEFT OUTER JOIN dbo.cvo_item_pricing_analysis o (NOLOCK) ON o.cust_code = ar.customer_code AND o.ship_to = ar.ship_to_code
JOIN inv_master i (NOLOCK) ON i.part_no = o.part_no
WHERE i.type_code IN ('frame','sun')
	AND o.promo_id IN ('pc','style out')
	AND o.date_entered BETWEEN  @startdate AND @enddate
	AND ISNULL(o.promo_id,'') <> ''
	AND ar.customer_code = ISNULL(@cust,ar.customer_code)
GROUP BY ar.customer_code, CASE WHEN ar.status_type = 1 THEN ar.ship_to_code ELSE '' END
-- free freight
INSERT #narrative (cust_code, ship_to, ben_type, ben_title, val_3_dec)
SELECT ar.customer_code cust_code, CASE WHEN ar.status_Type = 1 THEN ar.ship_to_code ELSE '' END AS ship_to
, ben_type = 'Free Frame Benefit'
, ben_title = 'Free Shipping'
, val_3_dec =  CAST(ISNULL(SUM(dbo.f_cvo_freightratelookup(c.carrier_code, LEFT(o.ship_to_zip,5), c.cs_dim_weight )),0) AS DECIMAL(10,2))
--, sentence = 
--'Free Shipping : ' + 
--CAST(CAST(ISNULL(SUM(dbo.f_cvo_freightratelookup(c.carrier_code, LEFT(o.ship_to_zip,5), c.cs_dim_weight )),0) AS DECIMAL(10,2)) AS VARCHAR(15))
FROM armaster ar (NOLOCK) 
INNER JOIN dbo.orders o (NOLOCK) ON o.cust_code = ar.customer_code AND o.ship_to = ar.ship_to_code
JOIN dbo.tdc_carton_tx c (NOLOCK) ON c.order_no = o.order_no AND c.order_ext = o.ext
WHERE  1=1
AND ar.customer_code = ISNULL(@cust,ar.customer_code)
AND o.tot_ord_freight = 0
AND o.status = 't' 
AND o.freight_allow_type NOT IN ('collect','thrdprty')
AND o.date_entered BETWEEN @startdate AND @enddate

GROUP BY ar.customer_code ,
        CASE WHEN ar.status_Type = 1 THEN ar.ship_to_code ELSE '' END

-- Value Add Benefits

-- RX/ST service level
INSERT #narrative (cust_code, ship_to, ben_type, ben_title, val_1_lbl, val_1_int, val_3_lbl, val_3_dec)
SELECT ar.customer_code cust_code, CASE WHEN ar.status_type = 1 THEN ar.ship_to_code ELSE '' END AS ship_to
, ben_type = 'Value Add'
, ben_title = 'Order Service Level ' + CASE WHEN o.user_category LIKE 'RX%' THEN 'RX' ELSE 'ST' END  
, val_1_lbl = 'Avg. Days to Ship: '
, val_1_int = CAST(AVG(DATEDIFF(dd,ol.time_entered, o.date_shipped)) AS INTEGER) 
, val_3_lbl = 'Fill Rate %'
, val_3_dec = CAST(CASE WHEN SUM(ol.ordered) <> 0 THEN SUM(ol.shipped)/SUM(ol.ordered) ELSE 0 END AS DECIMAL(10,2))*100
--, sentence = 
-- 'Order Service Level: ' 
-- + CASE WHEN o.user_category LIKE 'RX%' THEN 'RX' ELSE 'ST' END  
-- + ' Fill Rate % ' 
-- + CAST(CAST(CASE WHEN SUM(ol.ordered) <> 0 THEN SUM(ol.shipped)/SUM(ol.ordered) ELSE 0 END AS DECIMAL(10,2))*100 AS varchar(15))
-- + ' Avg. Days to Ship: ' + CAST(CAST(AVG(DATEDIFF(dd,ol.time_entered, o.date_shipped)) AS INTEGER) AS VARCHAR(15)) 
FROM armaster ar (NOLOCK) 
INNER JOIN orders o (NOLOCK) ON o.cust_code = ar.customer_code AND o.ship_to = ar.ship_to_code
INNER JOIN ord_list ol (NOLOCK) ON o.order_no = ol.order_no AND o.ext = ol.order_ext
WHERE o.date_entered BETWEEN @startdate AND @enddate
AND ar.customer_code = ISNULL(@cust,ar.customer_code)
AND o.status = 't' AND o.type = 'i'
AND o.who_entered <> 'backordr'
GROUP BY CASE WHEN o.user_category LIKE 'RX%' THEN 'RX'
         ELSE 'ST'
         END ,
         ar.customer_code ,
         CASE WHEN ar.status_type = 1 THEN ar.ship_to_code ELSE '' END 

-- warranty return rate
INSERT #narrative (cust_code, ship_to, ben_type, ben_title, val_3_lbl, val_3_dec)
SELECT ar.customer_code cust_code, CASE WHEN ar.status_type = 1 THEN s.ship_to ELSE '' END AS ship_to
, ben_type = 'Value Add'
, ben_title = 'Warranty Returns'
, val_3_lbl = '%'
, val_3_dec = CAST(ISNULL( CASE WHEN SUM(ISNULL(asales,0)) <> 0 
						THEN SUM(CASE WHEN ISNULL(s.return_code,'') = 'wty' 
										THEN ISNULL(areturns,0) ELSE 0 END)/SUM(ISNULL(asales,0)) END ,0) AS decimal(10,2))*100
												
FROM armaster ar (NOLOCK) 
LEFT OUTER JOIN dbo.cvo_sbm_details s (NOLOCK) ON ar.customer_code = s.customer AND ar.ship_to_code = s.ship_to
WHERE 1=1
AND ar.customer_code = ISNULL(@cust,ar.customer_code)
AND s.yyyymmdd BETWEEN @startdate AND @enddate
AND s.user_category NOT LIKE '%rb'
GROUP BY ar.customer_code,
         CASE WHEN ar.status_type = 1 THEN s.ship_to ELSE '' END

-- coop used

if (select object_id('tempdb..#coop')) is not null 
 	drop table #coop
	  
CREATE TABLE #coop
(terr VARCHAR(10), slp VARCHAR(10)
, customer_code VARCHAR(10)
, customer_name VARCHAR(40)
, coop_thresh DECIMAL(20,8)
, coop_cust_rate DECIMAL(20,8)
, desig VARCHAR(10)
, yyear INT
, coop_sales DECIMAL(20,8)
, coop_earned DECIMAL(20,8)
, coop_redeemed DECIMAL(20,8)
)

INSERT #coop (terr, slp, customer_code, customer_name, coop_thresh, coop_cust_rate, desig, yyear, coop_sales, coop_earned, coop_redeemed)
EXEC dbo.cvo_coop_status_sp @cust

INSERT #narrative (cust_code, ship_to, ben_type, ben_title, val_3_lbl, val_3_dec, val_4_lbl, val_4_dec)
SELECT #coop.customer_code cust_code,
	   '' AS ship_to
	   , ben_type = 'Value Add'
	   , ben_title = 'Co-op'
	   , val_3_lbl = 'Earned'
	   , val_3_dec = CAST(SUM(coop_earned) AS DECIMAL(10,2))
	   , val_4_lbl = 'Used'
	   , val_4_dec = CAST(SUM(coop_redeemed) AS DECIMAL(10,2))
	   --sentence = 
	   --'Co-op Used: ' + CAST(CAST(coop_redeemed AS DECIMAL(10,2)) AS varchar(15))
       FROM #coop 
	   WHERE #coop.yyear = DATEPART(YEAR, @enddate)
	   AND #coop.customer_code IS NOT NULL
	   GROUP BY customer_code


-- average rx orders / week

INSERT #narrative (cust_code, ship_to, ben_type, ben_title, val_1_lbl, val_1_int, val_2_lbl, val_3_lbl, val_3_dec)
SELECT w.cust_code, w.ship_to,
ben_type = 'Value Add'
,ben_title = 'Avg RX Orders/WEEK'
, val_1_lbl = 'Num Orders'
, val_1_int = CAST(AVG(numorders) AS INTEGER) 
, val_2_lbl = CASE WHEN AVG(numorders) > 2 THEN 'Join our RX Express Program for Free Shipping' ELSE '' end
, val_3_lbl = 'Avg Frames/Order'
, val_3_dec = CAST(AVG(qsales) AS DECIMAL(10,2))
--sentence =  'Avg RX Orders/Week: ' 
--+ CAST(CAST(AVG(numorders) AS INTEGER) AS VARCHAR(10))
--+ ' - ' + CAST(CAST(AVG(qsales) AS DECIMAL(10,2)) AS VARCHAR(10)) + ' Frames/Order'
from
(
SELECT ar.customer_code cust_code, CASE WHEN ar.status_type = 1 THEN ar.ship_to_code ELSE '' END AS ship_to, COUNT(DISTINCT yyyymmdd) numorders, SUM(qsales) qsales, DATEPART(WEEK, yyyymmdd) weeknum
FROM armaster ar (NOLOCK) 
LEFT OUTER join cvo_sbm_details s (NOLOCK) ON s.customer = ar.customer_code AND s.ship_to = ar.ship_to_code
JOIN dbo.inv_master i (NOLOCK) ON i.part_no = s.part_no
WHERE 1=1
AND ar.customer_code = ISNULL(@cust,ar.customer_code)
AND s.yyyymmdd BETWEEN @startdate AND @enddate
AND s.user_category NOT LIKE '%rb'
AND s.user_category LIKE 'rx%' 
AND i.type_code IN ('frame','sun')
GROUP BY DATEPART(WEEK, yyyymmdd) ,
         ar.customer_code ,
         CASE WHEN ar.status_type = 1 THEN ar.ship_to_code ELSE '' END 
) AS w
GROUP BY w.cust_code ,
         w.ship_to


IF(OBJECT_ID('dbo.cvo_cust_benefit_scorecard_tbl') is null)
BEGIN
CREATE TABLE [dbo].[cvo_cust_benefit_scorecard_tbl](
	[cust_code] [VARCHAR](10) NULL,
	[ship_to] [VARCHAR](8) NULL,
	[address_name] VARCHAR(200) NULL,
	[seq] [INT] NOT NULL,
	[ben_type] [VARCHAR](60) NULL,
	[ben_title] [VARCHAR](60) NULL,
	[val_1_lbl] [VARCHAR](60) NULL,
	[val_1_int] [INT] NULL,
	[val_2_lbl] [VARCHAR](60) NULL,
	[val_2_int] [INT] NULL,
	[val_3_lbl] [VARCHAR](60) NULL,
	[val_3_dec] [DECIMAL](20, 8) NULL,
	[val_4_lbl] [VARCHAR](60) NULL,
	[val_4_dec] [DECIMAL](20, 8) NULL
) ON [PRIMARY]
GRANT  SELECT, INSERT, UPDATE, DELETE ON dbo.cvo_cust_benefit_scorecard_tbl TO PUBLIC
CREATE CLUSTERED INDEX [pk_cust_beni_idx] ON [dbo].[cvo_cust_benefit_scorecard_tbl]
(
	[cust_code] ASC,
	[ship_to] ASC,
	[seq] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, 
	   DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

END

TRUNCATE TABLE dbo.cvo_cust_benefit_scorecard_tbl

INSERT dbo.cvo_cust_benefit_scorecard_tbl
        ( cust_code ,
          ship_to ,
		  seq,
          ben_type ,
          ben_title ,
          val_1_lbl ,
          val_1_int ,
          val_2_lbl ,
          val_2_int ,
          val_3_lbl ,
          val_3_dec ,
          val_4_lbl ,
          val_4_dec
        )

SELECT cust_code = 
		 CASE WHEN LEN(cust_code) = 6 THEN cust_code ELSE 
				(SELECT TOP 1 #t.cust_code FROM #t WHERE #narrative.cust_code = RIGHT(#t.cust_code,5)) END ,
       ship_to ,
	   seq,
       ben_type ,
       ben_title ,
	   CASE WHEN val_1_int IS NULL THEN NULL else ISNULL(val_1_lbl,'') end,
       val_1_int ,
       CASE WHEN val_2_int IS NULL THEN NULL ELSE ISNULL(val_2_lbl,'') end,
       val_2_int ,
       CASE WHEN val_3_dec IS NULL THEN NULL ELSE ISNULL(val_3_lbl,'') end,
       val_3_dec ,
       CASE WHEN val_4_dec IS NULL THEN NULL ELSE ISNULL(val_4_lbl,'') end,
       val_4_dec
 From #narrative
 WHERE  CASE WHEN LEN(cust_code) = 6 THEN cust_code ELSE 
				(SELECT TOP 1 #t.cust_code FROM #t WHERE #narrative.cust_code = RIGHT(#t.cust_code,5)) END
 IS NOT NULL
 
 ORDER BY cust_code, ship_to, seq

 UPDATE sc SET sc.address_name = ar.addr2+' '+ar.city+' '+ar.state+', '+ar.postal_code
 FROM dbo.cvo_cust_benefit_scorecard_tbl sc
 JOIN armaster ar ON ar.customer_code = sc.cust_code AND ar.ship_to_code = sc.ship_to

 -- select * From cvo_cust_benefit_scorecard_Tbl where cust_code = '043105'








GO
