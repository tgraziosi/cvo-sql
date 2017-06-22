SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CVO_b2b_move_sp]
	 @order_no		INT
	,@order_ext		INT
	,@location		VARCHAR (10)
	,@line_no		INT
	,@part_no		VARCHAR (30)
	,@qty_to_move	DECIMAL(20,8)
	,@bin_to		VARCHAR (12)  
	,@direction		INT

AS

BEGIN

	DECLARE  @lot_ser		VARCHAR (25)  
			,@bin_from		VARCHAR (12)  
			--,@bin_to		VARCHAR (12)  
			,@date_expires	DATETIME      
			,@qty			DECIMAL (20,8)
			,@who_entered	VARCHAR (50)
	
	/*SET @order_no =  281
	SET @order_ext = 0
	SET @location = 'Dallas'
	SET @part_no = 'FRAME001-WMS'
	SET @line_no  = 1
	SET @qty_to_move = 1*/
	
	--SET @bin_to      = 'Custom'	
	SET @who_entered = 'manager'	

--	IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL 
--		DROP TABLE #temp_who
--
--	CREATE TABLE #temp_who 
--	(who		VARCHAR(50) NOT NULL
--	,login_id	VARCHAR(50) NOT NULL)
--
--	INSERT INTO #temp_who (who      , login_id ) 
--	VALUES				  ('manager', 'manager')
--
--	IF (SELECT OBJECT_ID('tempdb..#adm_bin_xfer')) IS NOT NULL 
--		DROP TABLE #adm_bin_xfer
--		
--	CREATE TABLE #adm_bin_xfer 
--	(issue_no		INT					NULL,
--	location		VARCHAR (10)	NOT NULL,
--	part_no			VARCHAR (30)	NOT NULL,
--	lot_ser			VARCHAR (25)	NOT NULL,
--	bin_from		VARCHAR (12)	NOT NULL,
--	bin_to			VARCHAR (12)	NOT NULL,
--	date_expires	DATETIME		NOT NULL,
--	qty				DECIMAL(20,8)	NOT NULL,
--	who_entered		VARCHAR (50)	NOT NULL,
--	reason_code		VARCHAR (10)		NULL,
--	err_msg			VARCHAR (255)		NULL,
--	row_id			INT IDENTITY	NOT NULL)

	IF @direction = 1
	BEGIN
		--b2b while exists qty avail
		WHILE @qty_to_move > 0		
			BEGIN	
				SET @qty = 0																														  -- Sum of the quantity in lot_bin_stock   -- Subtract the quantity allocated   
				SELECT TOP 1 @lot_ser = lb.lot_ser, @bin_from = lb.bin_no, @date_expires = lb.date_expires, @qty = (SUM(qty) - (SELECT ISNULL(( SELECT SUM(qty) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE location = lb.location AND part_no = lb.part_no AND lot_ser = lb.lot_ser AND bin_no = lb.bin_no),0)))
				FROM       lot_bin_stock lb (NOLOCK), tdc_bin_master bm (NOLOCK) -- v1.1             
				WHERE      lb.bin_no     = bm.bin_no	AND   
		  				   lb.location   = bm.location	AND
		  				   lb.location   = @location	AND 
		  				   lb.part_no    = @part_no		AND
						   lb.bin_no	<> @bin_to
				GROUP BY   lb.location, lb.part_no, lb.lot_ser, lb.bin_no, lb.date_expires, bm.usage_type_code, lb.qty          
				HAVING     SUM(qty) > (SELECT ISNULL((SELECT SUM(qty) FROM tdc_soft_alloc_tbl(NOLOCK) WHERE location = lb.location AND part_no = lb.part_no AND lot_ser = lb.lot_ser AND bin_no = lb.bin_no),0))

				IF @qty > 0
					BEGIN
						IF @qty > @qty_to_move
							BEGIN 
								SET @qty		 = @qty_to_move
								SET @qty_to_move = 0
							END 
						ELSE
							SET @qty_to_move = @qty_to_move - @qty									
						
--						INSERT INTO #adm_bin_xfer (issue_no,  location,  part_no,  lot_ser,  bin_from,  bin_to,  date_expires,  qty,  who_entered, reason_code, err_msg) 													
--						VALUES					  (NULL    , @location, @part_no, @lot_ser, @bin_from, @bin_to, @date_expires, @qty, @who_entered, NULL       , NULL   )

						IF NOT EXISTS(SELECT * FROM CVO_disassembled_frame_B2B_history_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND location = @location AND line_no = @line_no AND part_no   = @part_no )
							INSERT INTO CVO_disassembled_frame_B2B_history_tbl (order_no,  order_ext,  location,  line_no,  part_no,  lot_ser,  bin_from,  bin_to,   qty) 													
							VALUES											(@order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @bin_from, @bin_to,  @qty)
						ELSE
							UPDATE CVO_disassembled_frame_B2B_history_tbl
							SET    qty		 = qty + @qty
							WHERE  order_no  = @order_no  AND 
								   order_ext = @order_ext AND 
								   location  = @location  AND			
								   line_no   = @line_no   AND 
								   part_no   = @part_no   		

--						EXEC tdc_bin_xfer
						
					END 
				ELSE
					SET @qty_to_move = 0				
		END -- end while
	END --end @direction = 1
	
	IF @direction = -1
	BEGIN
		SELECT 	@lot_ser	= lot_ser
			   ,@bin_from	= bin_to
			   ,@bin_to		= bin_from
		FROM   CVO_disassembled_frame_B2B_history_tbl (NOLOCK) -- v1.1
		WHERE  order_no  = @order_no  AND 
			   order_ext = @order_ext AND 
			   location  = @location  AND			
			   line_no   = @line_no   AND 
			   part_no   = @part_no

		SELECT @qty	= @qty_to_move			  			  			  

		SELECT @date_expires = date_expires
		FROM   lot_bin_stock (NOLOCK) -- v1.1           
		WHERE  location = @location	AND 
			   part_no  = @part_no	AND
			   bin_no   = @bin_from	AND
			   lot_ser	= @lot_ser

--		INSERT INTO #adm_bin_xfer (issue_no,  location,  part_no,  lot_ser,  bin_from,  bin_to,  date_expires,  qty,  who_entered, reason_code, err_msg) 													
--		VALUES					  (NULL    , @location, @part_no, @lot_ser, @bin_from, @bin_to, @date_expires, @qty, @who_entered, NULL       , NULL   )

		UPDATE CVO_disassembled_frame_B2B_history_tbl
		SET    qty		 = qty - @qty
		WHERE  order_no  = @order_no  AND 
			   order_ext = @order_ext AND 
			   location  = @location  AND			
			   line_no   = @line_no   AND 
			   part_no   = @part_no  
			   
--		EXEC tdc_bin_xfer 		
					
	END--end @direction = 1
	
 
END
-- Permissions  
GO
GRANT EXECUTE ON  [dbo].[CVO_b2b_move_sp] TO [public]
GO
