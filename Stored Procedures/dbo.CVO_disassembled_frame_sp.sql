SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CVO_disassembled_frame_sp]
		@order_no	INT
       ,@order_ext	INT          
AS

BEGIN

--return -- v1.1

DECLARE @location	VARCHAR (10)
       ,@line_no	INT
	   ,@part_no	VARCHAR (30)
       ,@ordered	DECIMAL (20,8)   

	SET NOCOUNT ON

	DECLARE parts_cur CURSOR FOR 
							 SELECT   ol.order_no, ol.order_ext, ol.line_no, ol.ordered, ol.part_no, ol.location
							 FROM     CVO_ord_list cvo, ord_list ol
							 WHERE    cvo.order_no		= ol.order_no	AND
									  cvo.order_ext		= ol.order_ext	AND
									  cvo.line_no		= ol.line_no	AND 
									  cvo.order_no		= @order_no		AND 
									  cvo.order_ext		= @order_ext	AND 
									  cvo.is_customized = 'S'
							 UNION ALL
							 SELECT   olk.order_no, olk.order_ext, olk.line_no, olk.ordered, olk.part_no, olk.location
							 FROM     cvo_ord_list_kit cvo, ord_list_kit olk	
							 WHERE    cvo.order_no	= olk.order_no		AND
									  cvo.order_ext = olk.order_ext		AND
									  cvo.location	= olk.location		AND
									  cvo.line_no	= olk.line_no		AND
									  cvo.part_no	= olk.part_no		AND									  
									  cvo.order_no	= @order_no			AND
									  cvo.order_ext = @order_ext		AND 
									  --cvo.line_no	= @line_no			AND 
									  cvo.replaced	= 'S'
	OPEN parts_cur

	FETCH NEXT FROM parts_cur 
	INTO @order_no, @order_ext, @line_no, @ordered, @part_no, @location

	WHILE @@FETCH_STATUS = 0
	BEGIN

		-- v1.2 Start
		IF OBJECT_ID('tempdb..#line_exclusions') IS NOT NULL
		BEGIN
			IF EXISTS (SELECT 1 FROM #line_exclusions WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no)
			BEGIN

			   FETCH NEXT FROM parts_cur 
			   INTO @order_no, @order_ext, @line_no, @ordered, @part_no, @location

				CONTINUE

			END
		END
		-- v1.2 End

	   IF EXISTS (SELECT * FROM CVO_disassembled_frame_B2B_history_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND location = @location AND line_no = @line_no AND part_no   = @part_no)
		BEGIN
			SELECT @ordered = @ordered - qty
			FROM   CVO_disassembled_frame_B2B_history_tbl (NOLOCK)
			WHERE  order_no  = @order_no	AND 
				   order_ext = @order_ext	AND
				   location  = @location	AND
				   line_no   = @line_no		AND 
				   part_no   = @part_no							   
		END	   
		--SELECT  @ordered 			
		IF @ordered > 0 
		BEGIN
			EXEC CVO_b2b_move_sp @order_no, @order_ext, @location, @line_no, @part_no, @ordered, 'Custom', 1
		END

		IF @ordered < 0 
		BEGIN
			SET @ordered = ABS(@ordered)
			EXEC CVO_b2b_move_sp @order_no, @order_ext, @location, @line_no, @part_no, @ordered, '-1',	  -1			 				   				   
		END

	   FETCH NEXT FROM parts_cur 
	   INTO @order_no, @order_ext, @line_no, @ordered, @part_no, @location
	END

	CLOSE parts_cur
	DEALLOCATE parts_cur
END
GO
GRANT EXECUTE ON  [dbo].[CVO_disassembled_frame_sp] TO [public]
GO
