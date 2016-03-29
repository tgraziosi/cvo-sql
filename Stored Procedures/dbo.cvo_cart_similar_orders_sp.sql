
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_cart_similar_orders_sp] (@baseorder_no INT, @base_ext int)
AS

BEGIN

SET NOCOUNT ON;


-- usage:
-- exec cvo_cart_similar_orders_sp 2692549, 0
/* 
 select * From cvo_adord_vw where status = 'n' and date_sch_ship <= '03/29/2016' 
 and who_entered <> 'backordr' and order_type like 'st%' and framesordered > 5 -- open order list

 select part_no, count(order_no) num_orders, min(order_no) min_order_no
  -- select * 
  from cvo_open_order_detail_vw
  where allocation_date <= getdate() and sch_ship_date <= getdate()
  and status = 'n' and restype in ('frame','sun') and qty_avl > 0
  group by part_no
 order by count(order_no) desc

*/

DECLARE @threshold INT, 
-- @baseorder_no INT, @base_ext INT, 
@totalordlist INT, @thresholdord_list int


SELECT @threshold = 0 --, @baseorder_no = 2622825 , @base_ext = 0

SELECT @totalordlist = COUNT(*) FROM ord_list WHERE order_no = @baseorder_no AND order_ext = @base_ext
-- SELECT @totalordlist

SELECT @thresholdord_list = @threshold* @totalordlist/100

-- SELECT @thresholdord_list

IF(OBJECT_ID('tempdb.dbo.#O') is not null)  drop table #O
SELECT TOP 100 REPLACE(CAST(@baseorder_no AS VARCHAR(8))+'-'+CAST(@base_ext AS varCHAR(2)),' ','') base_order
, allorder.order_no, allorder.order_ext,  o.sch_ship_date, CO.allocation_date, co.promo_id, co.promo_level, COUNT(*) Common_items
INTO #o
FROM ord_list (NOLOCK) sample
JOIN ord_list (NOLOCK) ALLorder ON allorder.part_no = sample.part_no
LEFT OUTER JOIN dbo.cvo_hard_allocated_vw H ON 
	 H.line_no = ALLorder.line_no AND H.order_ext = ALLorder.order_ext AND H.order_no = ALLorder.order_no
JOIN orders (NOLOCK) o ON o.order_no = ALLorder.order_no AND o.ext = allorder.order_ext
JOIN cvo_orders_all (NOLOCK) co ON co.ext = o.ext AND co.order_no = o.order_no
JOIN inv_master i (NOLOCK) ON i.part_no = allorder.part_no

WHERE sample.order_no = @baseorder_no AND sample.order_ext = @base_ext
	AND sample.order_no <> allorder.order_no 
and o.status in ('n')
-- and o.user_category like 'st%'
and o.type = 'i'
AND i.type_code IN ('frame','sun')
AND ISNULL(CO.st_consolidate,0) = 0
AND co.allocation_date <= GETDATE()
AND o.sch_ship_date <= GETDATE()
group by allorder.order_no, allorder.order_ext, co.promo_id, co.promo_level, o.sch_ship_date, CO.allocation_date
HAVING
COUNT(*) > @thresholdord_list
-- ORDER BY COUNT(*) DESC, o.sch_ship_date

INSERT INTO #O
SELECT REPLACE(CAST(@baseorder_no AS VARCHAR(8))+'-'+CAST(@base_ext AS varCHAR(2)),' ','') base_order
, o.order_no, o.ext,  o.sch_ship_date, CO.allocation_date, co.promo_id, co.promo_level, 999 Common_items
FROM orders (NOLOCK) o
JOIN cvo_orders_all (NOLOCK) co ON co.ext = o.ext AND co.order_no = o.order_no
WHERE o.order_no = @baseorder_no AND o.ext = @base_ext
and o.status in ('n')
and o.type = 'i'

SELECT base_order ,
       order_no ,
       order_ext ,
       sch_ship_date ,
       allocation_date ,
       promo_id ,
       promo_level ,
       Common_items FROM #O
ORDER BY common_items DESC, sch_ship_date

END

GRANT ALL ON cvo_cart_similar_orders_sp TO PUBLIC
GO

GRANT EXECUTE ON  [dbo].[cvo_cart_similar_orders_sp] TO [public]
GO
