SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_order_after_save_wrap]     
  @order_no integer, @ext integer AS      

--  v2.0	TM 29-SEP-2011	Send email when Credit check fails
--	v3.0	TM 17-OCT-2011	Set freight type = COLLECT with routing is any 3RD Party
--  v3.1	CB 14-NOV-2011	Check for void
--  v3.2	CB 29-NOV-2011	Do not print custom frames if status is not new
--  v3.3	CB 06/01/2012	Call queue consolidation
--  v3.4    CB 09/02/2012	Check if a prior hold of NA exists and if so do not allocate
--  v3.5	CT 30/07/2012	Remove inserts/deletes of tdc_config option mod_ebo_inv	
--  v3.6	CB 04/09/2012	Consolidation no longer required - now at order entry
--	v3.7	CT 25/10/2012	After autoshipping rep orders, mark soft alloc records as processed
--  v3.8	CB 26/07/2013	Call to ship rep orders should exclude rebill orders 
--	v3.9	CT 29/01/2014	Issue #1413 - Remove logic to set COLLECT for 3rd party carrier


DECLARE @rc int 

-- v3.4 START
SET @rc = 0

IF NOT EXISTS(SELECT 1 FROM dbo.CVO_Orders_all WHERE order_no = @order_no AND ext = @ext AND ISNULL(prior_hold,'') = 'NA')
BEGIN
     
    
	EXEC @rc = tdc_order_after_save @order_no, @ext   
	SELECT @rc  

	if (@rc = 0) 
	BEGIN
		-- v3.6 EXEC dbo.CVO_Consolidate_Pick_queue_sp @order_no, @ext -- v3.3

		IF EXISTS(SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND status = 'N') -- v3.2 START
		BEGIN
			IF EXISTS(SELECT * FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND is_customized = 'S') 
		--	AND EXISTS(SELECT * FROM cvo_orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND flag_print = 1)
			BEGIN
				-- START v3.5
				/*
				IF NOT EXISTS (SELECT * FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv')
						INSERT INTO tdc_config ([function],mod_owner, description, active) VALUES ('mod_ebo_inv','EBO','Allow modify inventory from eBO','Y')	
				*/
				-- END v3.5

				IF (OBJECT_ID('tempdb..#PrintData') IS NOT NULL) 
					DROP TABLE #PrintData

				CREATE TABLE #PrintData 
				(row_id			INT IDENTITY (1,1)	NOT NULL
				,data_field		VARCHAR(300)		NOT NULL
				,data_value		VARCHAR(300)			NULL)
					
				EXEC CVO_disassembled_frame_sp				@order_no, @ext
				
				EXEC CVO_disassembled_inv_adjust_sp			@order_no, @ext
					
				EXEC CVO_disassembled_print_inv_adjust_sp	@order_no, @ext		
					
				UPDATE cvo_orders_all 
				SET    flag_print = 2 
				WHERE  order_no   = @order_no AND 
					   ext		  = @ext
				
				-- START v3.5
				--DELETE FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv'
				-- END v3.5
					
			END
		END -- v3.2 END
	END
END -- v3.4 END
ELSE
	SELECT @rc  
--  
-- TMcGrady  OCT.2010 Set Line Revenue based on Territory  
--  
IF EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND status <> 'V') -- v3.1
BEGIN
	EXEC CVO_Set_Revenue_Acct_sp  @Order_no, @ext  
END

-- v2.0 BEG
IF EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND status = 'C')
BEGIN
	EXEC dbo.CVO_email_credithold_sp @order_no
END
-- v2.0 END 


IF EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND status <> 'V' -- v3.1
			AND location >= '100' AND location <= '999' AND UPPER(RIGHT(user_category,2)) <> 'RB') -- v3.8
BEGIN
	EXEC dbo.CVO_Ship_Rep_Orders_sp @order_no, @ext

	-- START v3.7
	IF EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND status = 'R')
	BEGIN
		UPDATE	dbo.cvo_soft_alloc_hdr
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext = @ext
		AND		status <> -2

		UPDATE	dbo.cvo_soft_alloc_det
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext = @ext
		AND		status <> -2	
	END
	-- END v3.7
	RETURN
END

-- START v3.9
/*
-- v3.0 BEGIN
UPDATE orders SET freight_allow_type = 'COLLECT' WHERE order_no = @order_no AND ext = @ext AND routing LIKE '3%' AND status <> 'V' -- v3.1
-- v3.0 END
*/


-- CB 16/06/2011 - If any items not allocated then put them on backorder
--EXEC dbo.CVO_CreateBackOrders_sp @order_no, @ext


GO
GRANT EXECUTE ON  [dbo].[tdc_order_after_save_wrap] TO [public]
GO
