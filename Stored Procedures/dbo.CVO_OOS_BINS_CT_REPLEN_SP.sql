SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		ELIZABETH LABARBERA
-- Create date: 8/28/2013
-- Description:	FIND QTY'S IN BINS THAT NEED TO BE MOVED OVER FOR THE OUT OF STOCK REPORT
-- EXEC CVO_OOS_BINS_CT_REPLEN_SP 
-- =============================================
CREATE PROCEDURE [dbo].[CVO_OOS_BINS_CT_REPLEN_SP] 
AS
BEGIN
	SET NOCOUNT ON;
-- -- QTY'S IN CT BINS   -- REPLEN QTY NOT SA
select Type, T3.Category, t4.field_2 as Model, t4.field_3 as Color, 
(ISNULL(CAST(str(FIELD_17, 2, 0) AS VARCHAR(2)),'') + '/' + ISNULL(CAST(field_6 AS VARCHAR(2)),'') + '/' + ISNULL(CAST(field_8 AS VARCHAR(3)),'') ) as Size, t1.PART_NO, [Next PO Confirm Date], 
CASE WHEN [Next PO Inhouse Date] < getdate() THEN DATEADD(wk, DATEDIFF(week,0,getdate()),14)
WHEN [Next PO Inhouse Date] >= DateAdd(Week,7,getdate()) THEN DATEADD(wk, DATEDIFF(week,0,getdate()),56)
ELSE ISNULL([Next PO Inhouse Date], DATEADD(wk, DATEDIFF(week,0,getdate()),91) ) END AS [Next PO Inhouse Date],
[Next PO],[Open Order Qty], in_stock, Avail,
'CTBIN' AS AREA,
ISNULL((select sum(qty) from cvo_bin_inquiry_vw t11 where bin_no like 'ct%' and t1.part_no=t11.part_no),0) QTY,
0 as tran_id,
'' as FromBin,
'' as ToBin,
0 as AmtToMove,
getdate() as AsOfDate
from cvo_out_of_stock_vw (nolock) t1
join inv_master (nolock) t3 on t1.part_no=t3.part_no
join inv_master_add (nolock) t4 on t3.part_no=t4.part_no 
where avail <= -5
and type_code in ('sun','frame')
and ISNULL((select sum(qty) from cvo_bin_inquiry_vw t11 where bin_no like 'ct%' and t1.part_no=t11.part_no),0) > -1*Avail
and ( field_28 > getdate() OR field_28 is NULL )

  UNION ALL
select Type, T3.Category, t4.field_2 as Model, t4.field_3 as Color, 
(ISNULL(CAST(str(FIELD_17, 2, 0) AS VARCHAR(2)),'') + '/' + ISNULL(CAST(field_6 AS VARCHAR(2)),'') + '/' + ISNULL(CAST(field_8 AS VARCHAR(3)),'') ) as Size, t1.PART_NO, [Next PO Confirm Date], [Next PO Inhouse Date],
[Next PO],[Open Order Qty], t1.in_stock, Avail, 
'REPLEN_QTY_NOT_SA' AS AREA,
REPLEN_QTY_NOT_SA AS QTY,
t6.tran_id, 
t6.bin_no as FromBin, 
t6.next_op as ToBin, 
t6.qty_to_process as AmtToMove,
getdate() as AsOfDate
from cvo_out_of_stock_vw (nolock) t1
join inv_master (nolock) t3 on t1.part_no=t3.part_no
join inv_master_add (nolock) t4 on t3.part_no=t4.part_no 
JOIN CVO_ITEM_AVAIL_VW (NOLOCK) T5 ON T1.PART_NO=T5.PART_NO AND T1.LOCATION=T5.LOCATION
left outer join tdc_pick_queue t6 on T1.PART_NO=T6.PART_NO AND T1.LOCATION=T6.LOCATION
where avail <= -5
and t1.location='001'
and type_code in ('sun','frame')
and ISNULL((select sum(qty) from cvo_bin_inquiry_vw t11 where bin_no like 'ct%' and t1.part_no=t11.part_no AND t1.location=t11.location),0) !> -1*Avail
and ( field_28 > getdate() OR field_28 is NULL )
--and (Replen_qty_not_sa + ReplenQty) !> avail*-1
and t6.trans = 'mgtb2b'
and t6.next_op <> 'CUSTOM'
order by T3.Category, Type, t4.field_2, t4.field_3, t1.PART_NO

END



GO
