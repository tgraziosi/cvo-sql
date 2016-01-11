SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- exec daily_order_log_CH_RX_sp '01/08/2016'
-- tag 021414 - added qualifying order counts

CREATE PROCEDURE [dbo].[Daily_Order_Log_CH_RX_sp] @OrderDate DATETIME
AS
    BEGIN

        IF ( OBJECT_ID('tempdb.dbo.#T1') IS NOT NULL )
            DROP TABLE dbo.#T1;

        IF ( OBJECT_ID('tempdb.dbo.#T2') IS NOT NULL )
            DROP TABLE dbo.#T2

/*
declare @orderdate datetime
select @orderdate = '02/05/2014'
*/

		DECLARE @startdate DATETIME, @enddate DATETIME
		SELECT @startdate = CONVERT(VARCHAR, DATEADD(dd,1 - ( DATEPART(dw, @OrderDate) - 1 ), @OrderDate), 101)
		SELECT @enddate = CONVERT(VARCHAR, DATEADD(dd,( 9 - DATEPART(dw,   @OrderDate) ),     @OrderDate), 101)
                     
;
        WITH    C AS ( SELECT   ol.territory ,
                                ol.salesperson ,
                                ol.cust_code ,
                                ol.ship_to ,
                                ol.customer_name ,
                                ol.ORDER_NO ,
                                ol.date_entered ,
                                ol.tot_shp_qty ,
                                ol.status ,
                                ol.status_desc ,
                                ol.tot_ord_qty ,
                                promo_level ,
                                CASE WHEN promo_id = '' THEN '-'
                                     WHEN promo_id IS NULL THEN '-'
                                     ELSE promo_id
                                END AS promo_id ,
                                REPLACE(tracking, ' ', '') AS tracking ,
                                tot_inv_sales ,
                                date_shipped ,
                                DATENAME(dw, ol.date_entered) AS Day_Name ,
                                DATEPART(WEEKDAY, ol.date_entered) AS Day ,
-- tag - 021414
                                ROW_NUMBER() OVER ( PARTITION BY ol.cust_code,
                                                    DATENAME(dw,
                                                             ol.date_entered) ORDER BY ol.cust_code, DATENAME(dw,
                                                              ol.date_entered) ) AS UC ,
                                CASE WHEN ol.tot_ord_qty >= 5 THEN 1
                                END AS qual_order
                       FROM     
(select 
--top 100
o.ship_to_region as territory,
o.salesperson,
o.cust_code,
(select a.customer_name from arcust a (nolock) 
	where a.customer_code = o.cust_code and a.address_type = 0)
	as customer_name,
o.ship_to,
ship_to_name = ISNULL(
	case o.ship_to
	when '' then ''
	else (select a.ADDRESS_name from armaster a (nolock) 
		  where a.customer_code = o.cust_code and a.ship_to_code = o.ship_to)
	end,''),
o.ORDER_NO, 
o.ext, 
o.date_entered, 
o.date_shipped,
o.req_ship_date,
o.sch_ship_date,
o.invoice_date,
o.total_amt_order,
o.tot_ord_freight,
o.tot_ord_tax, 
ISNULL(ordlist.tot_ord_qty,0) tot_ord_qty,
ISNULL(ordlist.tot_shp_qty,0) tot_shp_qty,
 o.status,
 CASE o.status        
   WHEN 'A' THEN 'User Hold' -- per KB request 062413 
   WHEN 'B' THEN 'Credit Hold'        
   WHEN 'C' THEN 'Credit Hold'        
   WHEN 'E' THEN 'Other'        
   WHEN 'H' THEN 'User Hold' -- per KB request 062413        
   WHEN 'M' THEN 'Other'        
   WHEN 'N' THEN 'Received' 
   when 'P' then
	case 
	when isnull((select top (1) c.status from tdc_carton_tx c (nolock)  
		 where o.order_no = c.order_no and o.ext = c.order_ext
         and (c.void=0 or c.void is null)), '') IN ('F','S','X') then 'Shipped'       
	else 'Processing'
	end
   WHEN 'Q' THEN 'Processing'        
   WHEN 'R' THEN 'Shipped'        
   WHEN 'S' THEN 'Shipped'        
   WHEN 'T' THEN 'Shipped'        
   WHEN 'V' THEN 'Void'        
   WHEN 'X' THEN 'Void'        
   ELSE '' 
  END as status_desc,      
isnull(cvo.promo_id,'') as promo_id,
isnull(cvo.promo_level,'') as promo_level,
isnull(o.cust_po,'') as Cust_po,
-- o.ship_to_name,
o.ship_to_add_1,
o.ship_to_add_2,
o.ship_to_add_3,
o.ship_to_add_4,
o.ship_to_city,
o.ship_to_state,
o.ship_to_zip,
isnull(o.sold_to,'') as Global_ship_to,
isnull(o.sold_to_addr1,'') as Global_name,
case when 
	isnull((select top (1) c.cs_tracking_no from tdc_carton_tx c (nolock)  
	where o.order_no = c.order_no and o.ext = c.order_ext
       and (c.void=0 or c.void is null)), '') = '' then
	isnull((select top (1) c.carrier_code from tdc_carton_tx c (nolock)
	where o.order_no = c.order_no and o.ext = c.order_ext
       and (c.void=0 or c.void is null)), '')
	else isnull((select top (1) c.cs_tracking_no from tdc_carton_tx c (nolock)  
	where o.order_no = c.order_no and o.ext = c.order_ext
       and (c.void=0 or c.void is null)), '') 
	end as tracking,
o.who_entered,
o.gross_sales as tot_inv_sales,
o.freight as tot_inv_freight,
o.total_tax as tot_inv_tax,
O.INVOICE_NO,
o.user_category as OrderType,
o.type +'-'+left(o.user_category,2) as Type,
o.void

from orders o (nolock) 
inner join cvo_orders_all cvo (nolock)
on o.order_no = cvo.order_no and o.ext = cvo.ext
INNER JOIN
(select ol.order_no, ol.order_ext, SUM(shipped) tot_shp_qty, SUM(ordered) tot_ord_qty
 from ord_list ol (nolock)
 inner join inv_master i (nolock) on ol.part_no = i.part_no
 WHERE i.type_code in ('FRAME','SUN') AND i.category = 'CH'
 GROUP BY ol.order_no, ol.order_ext ) ordlist
	ON ordlist.order_no = o.order_no AND ordlist.order_ext = o.ext

WHERE o.status <> 'V' and o.void = 'N' and o.type='I' AND LEFT(o.user_category,2) = 'RX'
AND RIGHT(o.user_category, 2) NOT IN ( 'RB', 'TB', 'PM' ) AND who_entered <> 'BACKORDR'
AND date_entered BETWEEN @startdate AND @enddate
)	ol							
)

            SELECT  *
            INTO    #T1
            FROM    C;

        UPDATE  #T1
        SET     UC = NULL
        WHERE   UC <> 1

-- select #t1.uc*#t1.qual_order as qual_order,*  from #t1 order by cust_code, day

;
        WITH    C AS ( SELECT DISTINCT
                                r.territory_code ,
                                r.salesperson_code AS salesperson ,
                                dbo.calculate_region_fn(ar.territory_code) AS Region
-- TAG - UPDATE TAKE TERRITORY/REP FROM ARSALESP INSTEAD - AVOID DUPLICATES
                       FROM     arsalesp r -- tg - 2/1/2013 commented out match on sc due to reps having more than 1 territory and don't report
-- Marcella as a rep
                                JOIN armaster ar ( NOLOCK ) ON --r.salesperson_code = ar.salesperson_code and 
r.territory_code = ar.territory_code  -- EL added territory_code match 1/7/2012
                       WHERE    r.territory_code IS NOT NULL
                                AND salesperson_type = 0
                                AND r.status_type = 1
                                AND ( r.salesperson_code <> 'smithma'
                                      AND ar.salesperson_code <> 'smithma'
                                    )
-- order by r.territory_code
                     )
            SELECT  *
            INTO    #T2
            FROM    C;

        SELECT  ISNULL(c.territory_code, ol.territory) AS territory ,
                ISNULL(c.salesperson, ol.salesperson) AS salesperson ,
                ISNULL(c.Region, dbo.calculate_region_fn(ol.territory)) Region ,
                ol.cust_code ,
                ol.ship_to ,
                ol.customer_name ,
                ISNULL(ol.UC * ol.qual_order, 0) AS qual_order ,
                ol.ORDER_NO ,
                ol.date_entered ,
                ol.tot_shp_qty ,
                ol.status ,
                ol.status_desc ,
                ol.tot_ord_qty ,
                promo_level ,
                CASE WHEN promo_id IS NULL THEN '-'
                     ELSE promo_id
                END AS promo_id ,
                tracking ,
                tot_inv_sales ,
                date_shipped ,
                Day_Name ,
                Day
        FROM    #T2 c
                FULL OUTER JOIN #T1 ol ON c.territory_code = ol.territory
        ORDER BY Region ,
                territory ,
                ol.date_entered;
    END;

GO
