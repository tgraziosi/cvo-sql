SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROC [dbo].[cvo_hold_rel_date_allocations_sp] @order_no int,  
             @order_ext int  
AS  
BEGIN  
  
 -- Determine if any of the stock items on the order lines is prior to its release date  
 -- Release date is held in field_26 in the inv_master_add table 

  
 IF EXISTS (SELECT 1 FROM ord_list a (NOLOCK) JOIN inv_master_add b (NOLOCK)  
    ON a.part_no = b.part_no WHERE a.order_no = @order_no AND a.order_ext = @order_ext  
    AND b.field_26 > GETDATE())  
 BEGIN  

  -- One or more of the stock items has a release date in the future  
  -- Update the pick queue and set the trans on hold, set the mfg_batch field to REL_DATE  
  -- mfg_batch is multi use so need to check if it holds a value already  
  -- There may be records on hold already  
  
  -- If record on manual hold then flag  
  UPDATE tdc_pick_queue  
  SET  mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END  
  WHERE trans_type_no = @order_no  
  AND  trans_type_ext = @order_ext  
  AND  trans IN ('STDPICK','MGTB2B')  
  AND  tx_lock = 'H'  
  AND  PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0  
  AND  PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0  
  AND  line_no IN (SELECT line_no FROM dbo.f_hold_rel_date_lines(@order_no,@order_ext))  
  
  -- update with the rel date hold when not on a manual hold  
  UPDATE tdc_pick_queue  
  SET  tx_lock = 'H',  
    mfg_batch = CASE WHEN mfg_batch IS NULL THEN 'REL_DATE'  
         WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',REL_DATE'  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch END   
  WHERE trans_type_no = @order_no  
  AND  trans_type_ext = @order_ext  
  AND  trans IN ('STDPICK','MGTB2B')  
  AND  mfg_lot IS NULL  
  AND  PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) = 0  
  AND  line_no IN (SELECT line_no FROM dbo.f_hold_rel_date_lines(@order_no,@order_ext))  
  
  -- update with the rel date hold when it is on a manual hold  
  UPDATE tdc_pick_queue  
  SET  tx_lock = 'H',  
    mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END,  
    mfg_batch = CASE WHEN mfg_batch IS NULL THEN 'REL_DATE,HOLD'  
         WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',HOLD'  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',REL_DATE,HOLD'  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch + ',HOLD' END   
  WHERE trans_type_no = @order_no  
  AND  trans_type_ext = @order_ext  
  AND  trans IN ('STDPICK','MGTB2B')  
  AND  mfg_lot IS NOT NULL  
  AND  PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) = 0  
  AND  line_no IN (SELECT line_no FROM dbo.f_hold_rel_date_lines(@order_no,@order_ext))  
  
  -- update with the rel date hold when it is on a previous manual hold  
  UPDATE tdc_pick_queue  
  SET  tx_lock = 'H',  
    mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END,  
    mfg_batch = CASE WHEN mfg_batch IS NULL THEN 'REL_DATE'  
         WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',REL_DATE'  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch END   
  WHERE trans_type_no = @order_no  
  AND  trans_type_ext = @order_ext  
  AND  trans IN ('STDPICK','MGTB2B')  
  AND  PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) > 0  
  AND  line_no IN (SELECT line_no FROM dbo.f_hold_rel_date_lines(@order_no,@order_ext))  
  
  
  RETURN -1 -- So that the pick ticket does not print  
  
 END  
  
 -- Determine if any of the stock items on the order kit lines is prior to its release date  
 -- Release date is held in field_26 in the inv_master_add table  
 IF EXISTS (SELECT 1 FROM cvo_ord_list_kit a (NOLOCK) JOIN inv_master_add b (NOLOCK)  
    ON a.part_no = b.part_no WHERE a.order_no = @order_no AND a.order_ext = @order_ext  
    AND b.field_26 > GETDATE())  
 BEGIN  

  -- One or more of the stock items has a release date in the future  
  -- Update the pick queue and set the trans on hold, set the mfg_batch field to REL_DATE  
  -- mfg_batch is multi use so need to check if it holds a value already  
  UPDATE tdc_pick_queue  
  SET  mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END  
  WHERE trans_type_no = @order_no  
  AND  trans_type_ext = @order_ext  
  AND  trans IN ('STDPICK','MGTB2B')  
  AND  tx_lock = 'H'  
  AND  PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0  
  AND  PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0  
  AND  line_no IN (SELECT line_no FROM dbo.f_hold_rel_date_lines(@order_no,@order_ext))  
  
  -- update with the rel date hold when not on a manual hold  
  UPDATE tdc_pick_queue  
  SET  tx_lock = 'H',  
    mfg_batch = CASE WHEN mfg_batch IS NULL THEN 'REL_DATE'  
         WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',REL_DATE'  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch END   
  WHERE trans_type_no = @order_no  
  AND  trans_type_ext = @order_ext  
  AND  trans IN ('STDPICK','MGTB2B')  
  AND  mfg_lot IS NULL  
  AND  PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) = 0  
  AND  line_no IN (SELECT line_no FROM dbo.f_hold_rel_date_lines(@order_no,@order_ext))  
  
  -- update with the rel date hold when it is on a manual hold  
  UPDATE tdc_pick_queue  
  SET  tx_lock = 'H',  
    mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END,  
    mfg_batch = CASE WHEN mfg_batch IS NULL THEN 'REL_DATE,HOLD'  
         WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',HOLD'  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',REL_DATE,HOLD'  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch + ',HOLD' END   
  WHERE trans_type_no = @order_no  
  AND  trans_type_ext = @order_ext  
  AND  trans IN ('STDPICK','MGTB2B')  
  AND  mfg_lot IS NOT NULL  
  AND  PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) = 0  
  AND  line_no IN (SELECT line_no FROM dbo.f_hold_rel_date_lines(@order_no,@order_ext))  
  
  -- update with the rel date hold when it is on a previous manual hold  
  UPDATE tdc_pick_queue  
  SET  tx_lock = 'H',  
    mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END,  
    mfg_batch = CASE WHEN mfg_batch IS NULL THEN 'REL_DATE'  
         WHEN (PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',REL_DATE'  
         WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0 AND PATINDEX('%REL_DATE%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch END   
  WHERE trans_type_no = @order_no  
  AND  trans_type_ext = @order_ext  
  AND  trans IN ('STDPICK','MGTB2B')  
  AND  PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) > 0  
  AND  line_no IN (SELECT line_no FROM dbo.f_hold_rel_date_lines(@order_no,@order_ext))  
  
  RETURN -1 -- So that the pick ticket does not print  
  
 END  
  

 UPDATE a  
 SET  tx_lock = 'R',   
   mfg_batch = NULL  
 FROM dbo.tdc_pick_queue a   
 WHERE a.trans IN ('STDPICK','MGTB2B')  
 AND  a.trans_type_no = @order_no  
 AND  a.trans_type_ext = @order_ext  
 AND  PATINDEX('%SHIP_COMP%',mfg_batch) = 0  
 AND  PATINDEX('%REL_DATE%',mfg_batch) > 0  
 AND  PATINDEX('%HOLD%',mfg_batch) = 0  
 AND  ISNULL(mfg_lot, 0) <> 2  
  
 UPDATE a  
 SET  mfg_batch = NULL  
 FROM dbo.tdc_pick_queue a   
 WHERE a.trans IN ('STDPICK','MGTB2B')  
 AND  a.trans_type_no = @order_no  
 AND  a.trans_type_ext = @order_ext  
 AND  PATINDEX('%SHIP_COMP%',mfg_batch) = 0  
 AND  PATINDEX('%REL_DATE%',mfg_batch) > 0  
 AND  PATINDEX('%HOLD%',mfg_batch) = 0  
 AND  ISNULL(mfg_lot, 0) = 2  
  
 UPDATE a  
 SET  mfg_batch = REPLACE(mfg_batch,',REL_DATE', '')  
 FROM dbo.tdc_pick_queue a   
 WHERE a.trans IN ('STDPICK','MGTB2B')  
 AND  a.trans_type_no = @order_no  
 AND  a.trans_type_ext = @order_ext  
 AND  PATINDEX('%SHIP_COMP%',mfg_batch) > 0  
 AND  PATINDEX('%,REL_DATE%',mfg_batch) > 0  
  
 UPDATE a  
 SET  mfg_batch = REPLACE(mfg_batch,'REL_DATE,', '')  
 FROM dbo.tdc_pick_queue a   
 WHERE a.trans IN ('STDPICK','MGTB2B')  
 AND  a.trans_type_no = @order_no  
 AND  a.trans_type_ext = @order_ext  
 AND  PATINDEX('%SHIP_COMP%',mfg_batch) > 0  
 AND  PATINDEX('%REL_DATE,%',mfg_batch) > 0  
  
 UPDATE a  
 SET  mfg_batch = NULL  
 FROM dbo.tdc_pick_queue a   
 WHERE a.trans IN ('STDPICK','MGTB2B')  
 AND  a.trans_type_no = @order_no  
 AND  a.trans_type_ext = @order_ext  
 AND  PATINDEX('%SHIP_COMP%',mfg_batch) = 0  
 AND  PATINDEX('%REL_DATE%',mfg_batch) > 0  
 AND  PATINDEX('%HOLD%',mfg_batch) > 0  
  
 RETURN 0 -- No need for hold  

  
END  
GO
GRANT EXECUTE ON  [dbo].[cvo_hold_rel_date_allocations_sp] TO [public]
GO
