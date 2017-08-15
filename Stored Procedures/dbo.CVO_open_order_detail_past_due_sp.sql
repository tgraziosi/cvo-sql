SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CVO_open_order_detail_past_due_sp] (@location VARCHAR(1024) = null)
AS 

-- exec CVO_open_order_detail_past_due_sp '001'

DECLARE @loc VARCHAR(1024)

SELECT @loc = @location

CREATE TABLE #loc ([location] VARCHAR(10))
if @loc is NULL 
BEGIN
	insert into #loc (location)
	select DISTINCT la.[location] from dbo.locations_all AS la WHERE la.void = 'n'
end
else
begin
	INSERT INTO #loc ([location])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@loc)
END

SELECT ol.brand,
       ol.restype,
       ol.gender,
       ol.style,
       ol.part_no,
       ol.vendor,
       ol.pom_date,
       ol.qty_avl,
       ol.qty_Rec,
       ol.location,
       ol.NextPODueDate,
       ol.order_no,
       ol.ext,
       ol.line_no,
       ol.user_category,
       ol.hold_reason,
       ol.cust_code,
       ol.ship_to,
       ol.ship_to_name,
       ol.cust_po,
       ol.Territory,
       ol.CustomerType,
       ol.date_entered,
       ol.sch_ship_date,
       ol.open_ord_qty,
       ol.alloc_qty,
       ol.sa_qty_avail,
       ol.sa_qty_notavail,
       ol.DaysOverDue,
       ol.who_entered,
       ol.status,
       ol.bo_flg,
       ol.net_amt,
       ol.so_priority_code,
       ol.promo_id,
       ol.promo_level,
       ol.p_hold_reason,
       ol.allocation_date,
       ol.add_pattern,
       ol.ordered, consolidation_no = CAST(c.consolidation_no AS VARCHAR(10)) + ISNULL(
(SELECT ' Partial Hold'
								FROM dbo.cvo_masterpack_consolidation_det AS cmcd
								JOIN orders o ON o.order_no = cmcd.order_no AND o.ext = cmcd.order_ext 
								WHERE cmcd.consolidation_no = c.consolidation_no
								AND ISNULL(o.status,'n') < 'n' ),'')
FROM 
(SELECT DISTINCT order_no, o.ext, o.location
 FROM 
 #loc l 
 INNER JOIN orders o (NOLOCK)
 ON o.location = l.location
WHERE 1=1
AND datediff(d,o.sch_ship_date,getdate()) > 0
and o.status IN ('n')
AND o.so_priority_code <> 3
and who_entered <> 'backordr'
and right(user_category,2) <> 'rb'
) oo 
inner join cvo_orders_all co (nolock) on co.order_no = oo.order_no and co.ext = oo.ext
INNER JOIN 
( SELECT oll.brand,
         oll.restype,
         oll.gender,
         oll.style,
         oll.part_no,
         oll.vendor,
         oll.pom_date,
         oll.qty_avl,
         oll.qty_Rec,
         oll.location,
         oll.NextPODueDate,
         oll.order_no,
         oll.ext,
         oll.line_no,
         oll.user_category,
         oll.hold_reason,
         oll.cust_code,
         oll.ship_to,
         oll.ship_to_name,
         oll.cust_po,
         oll.Territory,
         oll.CustomerType,
         oll.date_entered,
         oll.sch_ship_date,
         oll.open_ord_qty,
         oll.alloc_qty,
         oll.sa_qty_avail,
         oll.sa_qty_notavail,
         oll.DaysOverDue,
         oll.who_entered,
         oll.status,
         oll.bo_flg,
         oll.net_amt,
         oll.so_priority_code,
         oll.promo_id,
         oll.promo_level,
         oll.p_hold_reason,
         oll.allocation_date,
         oll.add_pattern,
         oll.ordered 
FROM #loc JOIN 
cvo_open_order_detail_vw oll ON oll.location = #loc.location AND oll.qty_avl > 0)
ol ON ol.order_no = oo.order_no  AND ol.ext = oo.ext 
left outer join cvo_promotions p (nolock) on co.promo_id = p.promo_id and co.promo_level = p.promo_level
left outer join cvo_masterpack_consolidation_det c (NOLOCK) ON c.order_no = ol.order_no and c.order_ext = ol.ext
WHERE 1=1
and restype in ('frame','sun','parts')
-- and ol.qty_avl > 0 /*added 8/3/2015*/
-- order by brand, style, part_no

GO
GRANT EXECUTE ON  [dbo].[CVO_open_order_detail_past_due_sp] TO [public]
GO
