SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure [dbo].[CVO_Insert_PrintData_detail_sp]    Script Date: 05/26/2010  *****
SED004 -- Control Packing -- Print International Documents
Object:      Stored Procedure CVO_Insert_PrintData_detail_sp  
Source file: CVO_Insert_PrintData_detail_sp.sql
Author:		 Jesus Velazquez
Created:	 05/26/2010
Function:    After shipping save info to print documents in table #PrintData_detail
Modified:    
Calls:    
Called by:   WMS -- Shipping Screen
Copyright:   Epicor Software 2010.  All rights reserved.  
*/

CREATE PROCEDURE  [dbo].[CVO_Insert_PrintData_detail_sp]   
			@order_no  INT,
			@order_ext INT
AS

BEGIN

    TRUNCATE TABLE #PrintData_detail  	
	
	DECLARE @curr_precision INT

	SELECT @curr_precision  = curr_precision
	FROM   glcurr_vw 
	WHERE  currency_code = (SELECT curr_key 
							FROM   orders 
							WHERE  order_no = @order_no AND 
								   ext		= @order_ext)
	
	INSERT INTO #PrintData_detail (order_no, order_ext, carton_no, part_no_desc, type_code, add_case, line_no, from_line_no, material, origin, qty, unit_value, total_value, schedule_B_no)
	  
	SELECT cd.order_no					 AS order_no,
		   cd.order_ext					 AS order_ext,
		   cd.carton_no					 AS Box, 
		   ol.description				 AS Description, 
		   inv.type_code				 AS type_code,
		   cvo.add_case				     AS add_case,
		   cvo.line_no				     AS line_no,
		   cvo.from_line_no              AS from_line_no,
		   ISNULL( inv_add.field_10,'')  AS Material, 
		   ISNULL(gl.description,'')	 AS Origin, 
		   ol.shipped					 AS Qty,  
		   curr_price = CASE cvo.is_amt_disc
		   WHEN 'Y' THEN ROUND((ol.curr_price * ol.shipped),@curr_precision) -  ROUND((cvo.amt_disc * ol.shipped),@curr_precision) 
		   ELSE 
						 ROUND((ol.curr_price * ol.shipped),@curr_precision) - (ROUND((ol.curr_price * ol.shipped),@curr_precision) * ROUND((ol.discount /100),@curr_precision))
		   END,
		   ol.shipped * curr_price      AS Total_Value,
		   ISNULL(inv.cmdty_code,'')	AS schedule_B_no  -- dbo.gl_cmdty
	FROM   tdc_carton_detail_tx  cd, 
           ord_list				 ol, 
           CVO_ord_list			cvo, 
           inv_master			inv, 
           inv_master_add	inv_add, 
           gl_country			 gl,
		   #cartonsToShip		cts
	WHERE  cd.order_no		= ol.order_no		AND
		   cd.order_ext		= ol.order_ext		AND
		   cd.order_no		= cts.order_no		AND
		   cd.order_ext		= cts.order_ext		AND
		   cd.carton_no		= cts.carton_no		AND
		   cd.line_no		= ol.line_no		AND
		   cd.order_no		= cvo.order_no		AND
		   cd.order_ext		= cvo.order_ext		AND
		   cd.line_no		= cvo.line_no		AND  
		   cd.part_no		= inv_add.part_no	AND
		   cd.part_no		= inv.part_no		AND
		   gl.country_code	= inv.country_code	AND
		   cd.order_no		= @order_no			AND
		   cd.order_ext		= @order_ext	  
 
END
GO
GRANT EXECUTE ON  [dbo].[CVO_Insert_PrintData_detail_sp] TO [public]
GO
