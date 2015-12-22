SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[CVO_consolidated_shipping_sp]    Script Date: 09/01/2010  *****  
SED009 -- Order Pick to Auto Pack Out       
Object:      Procedure CVO_consolidated_shipping_sp    
Source file: CVO_consolidated_shipping_sp.sql  
Author:   Jesus Velazquez  
Created:  09/06/2010  
Function:    Charges freight to lowest order no in the package xxx for Master Pack  
Modified:      
Calls:      
Called by:   WMS74 -- PPS  
Copyright:   Epicor Software 2010.  All rights reserved.    
  
*/  
  
--  
-- T McGrady 02.DEC.2010  Recalc freight on master pack from CVO tables  
--  
-- v1.0 CB 27/03/2012 - Fix issue where customer has no shipping charges 
-- v1.1 CB 13/06/2012 - Fix issue with consolidated shipping charges not being set
--					  - The original code fetched the min of the order and ext, this is incorrect. It should do this in 2 passes
-- v1.2 CB 14/06/2012 - Always get the weight from inventory
-- v1.3 CB 21/06/2012 - Fix issue with the zip code, it should only compare the first 5 characters as per the other freight calcs
-- v1.4 CB 13/07/2012 - If the order has freight override then move to an order that doesn't
-- v1.5 CB 17/07/2012 -	Check for free shipping
-- v1.6 CB 12/11/2012 - Issue #882 - Remove over weight error
-- v1.7 CB 31/01/2013 - Code change as requested by CVO

CREATE PROCEDURE [dbo].[CVO_consolidated_shipping_sp]     
 @pack_no INT  
AS   
BEGIN  
  
 DECLARE @min_order           INT,  
            @min_ext             INT,   
            @sum_freight         DECIMAL(20,8),  
            @sum_tot_ord_freight DECIMAL(20,8)  
  
 DECLARE @frght_amt  DECIMAL (20, 8),      -- 02.DEC.2010  
   @Weight_code VARCHAR(255),       -- 02.DEC.2010  
   @Max_charge  DECIMAL (20, 8),      -- 02.DEC.2010  
   @zip_code  VARCHAR(15),        -- 02.DEC.2010  
   @weight   DECIMAL(20, 8),       -- 02.DEC.2010  
   @wght   DECIMAL(20, 8),       -- 02.DEC.2010  
   @carrier_code VARCHAR(255),       -- 02.DEC.2010  
   @freight_type VARCHAR(30)        -- 02.DEC.2010  
  
 IF (SELECT COUNT(ct.order_no)  
     FROM   tdc_master_pack_ctn_tbl mp (NOLOCK), tdc_carton_tx ct (NOLOCK), orders o (NOLOCK)  
     WHERE  mp.carton_no = ct.carton_no AND  
         ct.order_no  = o.order_no   AND  
         ct.order_ext = o.ext        AND  
         mp.pack_no  = @pack_no) > 1    
 BEGIN  
-- v1.4
--  SELECT @min_order           = MIN(ct.order_no) 
--      --@min_ext             = MIN(o.ext)  -- v1.1
--  FROM   tdc_master_pack_ctn_tbl mp (NOLOCK),   
--      tdc_carton_tx           ct (NOLOCK),   
--      orders                  o  (NOLOCK)  
--  WHERE  mp.carton_no = ct.carton_no AND  
--      ct.order_no  = o.order_no   AND  
--      ct.order_ext = o.ext        AND  
--      mp.pack_no   = @pack_no   
    
-- v1.4
--  -- v1.1 
--  SELECT @min_ext             = MIN(o.ext)  
--  FROM   tdc_master_pack_ctn_tbl mp (NOLOCK),   
--      tdc_carton_tx           ct (NOLOCK),   
--      orders                  o  (NOLOCK)  
--  WHERE  mp.carton_no = ct.carton_no AND  
--      ct.order_no  = o.order_no   AND  
--      ct.order_ext = o.ext        AND  
--      mp.pack_no   = @pack_no     AND
--	  ct.order_no =  @min_order -- v1.1  

	-- v1.4
	SELECT	TOP 1 @min_order = ct.order_no,
			@min_ext = ct.order_ext
	FROM	tdc_master_pack_ctn_tbl mp (NOLOCK),   
			tdc_carton_tx           ct (NOLOCK),   
			orders                  o  (NOLOCK),
			cvo_orders_all			cv (NOLOCK) -- v1.5  
	WHERE	mp.carton_no = ct.carton_no AND  
			ct.order_no  = o.order_no   AND  
			ct.order_ext = o.ext        AND  
			o.order_no = cv.order_no	AND -- v1.5
			o.ext = cv.ext				AND -- v1.5
			mp.pack_no   = @pack_no     AND
			ISNULL(o.freight_allow_type,'')  <> 'FRTOVRID' AND
			ISNULL(cv.free_shipping,'N') <> 'Y' -- v1.5
	ORDER BY ct.order_no ASC, ct.order_ext ASC

-- v1.4
IF (@min_order IS NULL)
	RETURN

-- v1.0 Start
IF EXISTS(SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @min_order AND ext = @min_ext AND freight_allow_type = 'FRTOVRID')
	RETURN
-- v1.0 End
    
  UPDATE o  
  SET    o.freight         = 0.0,   
      o.tot_ord_freight = 0.0  
  FROM   tdc_master_pack_ctn_tbl mp (NOLOCK),   
      tdc_carton_tx           ct (NOLOCK),   
      orders                  o  (NOLOCK)  
  WHERE  mp.carton_no = ct.carton_no AND  
      ct.order_no  = o.order_no   AND  
      ct.order_ext = o.ext        AND  
      mp.pack_no   = @pack_no         
  
-- 02.DEC.2010 BEGIN  
  SELECT @carrier_code = md.carrier_code, 
		 @weight = md.weight, @zip_code = md.zip   
  FROM   tdc_master_pack_tbl md (NOLOCK)  
  WHERE  md.pack_no = @pack_no   

-- v1.2
	SELECT	@weight = ISNULL(SUM(ca.pack_qty * i.weight_ea) ,0)
	FROM	tdc_carton_detail_tx ca (NOLOCK) 
	JOIN	inv_master i (NOLOCK) 
	ON		ca.part_no = i.part_no 
	JOIN	tdc_master_pack_ctn_tbl b
	ON		ca.carton_no = b.carton_no
	JOIN	orders_all o (NOLOCK)
	ON		ca.order_no = o.order_no
	AND		ca.order_ext = o.ext
	JOIN	cvo_orders_all cv (NOLOCK)
	ON		o.order_no = cv.order_no
	AND		o.ext = cv.ext
	WHERE	b.pack_no = @pack_no
	AND		ISNULL(o.freight_allow_type,'')  <> 'FRTOVRID' -- v1.4
	AND		ISNULL(cv.free_shipping,'N') <> 'Y' -- v1.5
  
  
  SELECT @wght = MAX(Max_weight)  
  FROM CVO_carriers  
  WHERE Carrier = @carrier_code AND  
    Lower_zip <= LEFT(@zip_code,5) AND  -- v1.3
    Upper_zip >= LEFT(@zip_code,5) -- v1.3  
  
  -- v1.6 Start
--  IF @weight > @wght  
--  BEGIN  
--  SELECT 1, 'Over ' + CAST(CAST(@wght AS DECIMAL(20,4)) AS VARCHAR(20)) + ' lbs. can’t ship ' + @carrier_code, 0.0  
--   RETURN  
--  END  
  -- v1.6 End
  
  SELECT @wght = MIN(Max_weight)  
  FROM CVO_carriers  
  WHERE Carrier = @carrier_code AND  
    Lower_zip <= LEFT(@zip_code,5) AND   -- v1.3
    Upper_zip >= LEFT(@zip_code,5) AND  -- v1.3
    Max_weight >= @weight  
  
  SELECT @Weight_code = MIN(Weight_code)  
  FROM CVO_carriers  
  WHERE Carrier = @carrier_code AND  
    Lower_zip <= LEFT(@zip_code,5) AND  -- v1.3
    Upper_zip >= LEFT(@zip_code,5) AND  -- v1.3
    Max_weight = @wght  
  
  SELECT  @weight = CEILING(@weight)  

  SELECT @frght_amt = ISNULL(MIN(Weights.charge), 0)  
  FROM CVO_weights Weights  
  WHERE Weight_code = @Weight_code AND  
	wgt = CEILING(CAST(@weight AS FLOAT)) -- v1.7
  -- v1.7wgt >= @weight  
   
  SELECT @Max_charge = MAX(Max_charge)  
  FROM CVO_carriers  
  WHERE Carrier = @carrier_code AND  
    Lower_zip <= LEFT(@zip_code,5) AND  -- v1.3
    Upper_zip >= LEFT(@zip_code,5)  -- v1.3
  
  IF @frght_amt > @Max_charge  
  BEGIN  
   SELECT 1, 'Over $' + CAST(CAST(@Max_charge AS MONEY) AS VARCHAR(20))  + ' can’t ship ' + @carrier_code, @frght_amt  
   RETURN  
  END  
-- 02.DEC.2010 END  
  
  UPDATE orders   
  SET    freight         = @frght_amt,   
      tot_ord_freight = @frght_amt  
  WHERE  order_no = @min_order AND  
      ext      = @min_ext  
 END  
END  
-- Permissions  
  
GO
GRANT EXECUTE ON  [dbo].[CVO_consolidated_shipping_sp] TO [public]
GO
