SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROC [dbo].[cvo_no_stock_hold_ship_complete_allocations_sp]	@order_no int,  
																@order_ext int  
AS  
BEGIN  
 
	SET NOCOUNT ON

   -- Update the pick queue records and place them on hold  
   -- If record on manual hold then flag  
   UPDATE tdc_pick_queue  
   SET  mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END  
   WHERE trans_type_no = @order_no  
   AND  trans_type_ext = @order_ext  
   AND  trans IN ('STDPICK','MGTB2B')  
   AND  tx_lock = 'H'  
   AND  PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0  
   AND  PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0  
  
   -- update with the rel date hold when not on a manual hold  
   UPDATE tdc_pick_queue  
   SET  tx_lock = 'H',  
     mfg_batch = CASE WHEN mfg_batch IS NULL THEN 'SHIP_COMP'  
          WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch  
          WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',SHIP_COMP'  
          WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch END   
   WHERE trans_type_no = @order_no  
   AND  trans_type_ext = @order_ext  
   AND  trans IN ('STDPICK','MGTB2B')  
   AND  mfg_lot IS NULL  
   AND  PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) = 0  
  
   -- update with the rel date hold when it is on a manual hold  
   UPDATE tdc_pick_queue  
   SET  tx_lock = 'H',  
     mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END,  
     mfg_batch = CASE WHEN mfg_batch IS NULL THEN 'SHIP_COMP,HOLD'  
          WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',HOLD'  
          WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',SHIP_COMP,HOLD'  
          WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch + ',HOLD' END   
   WHERE trans_type_no = @order_no  
   AND  trans_type_ext = @order_ext  
   AND  trans IN ('STDPICK','MGTB2B')  
   AND  mfg_lot IS NOT NULL  
   AND  PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) = 0  
  
   -- update with the rel date hold when it is on a previous manual hold  
   UPDATE tdc_pick_queue  
   SET  tx_lock = 'H',  
     mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END,  
     mfg_batch = CASE WHEN mfg_batch IS NULL THEN 'SHIP_COMP'  
          WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch  
          WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',SHIP_COMP'  
          WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch END   
   WHERE trans_type_no = @order_no  
   AND  trans_type_ext = @order_ext  
   AND  trans IN ('STDPICK','MGTB2B')  
   AND  PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) > 0  
 
END  
GO
GRANT EXECUTE ON  [dbo].[cvo_no_stock_hold_ship_complete_allocations_sp] TO [public]
GO
