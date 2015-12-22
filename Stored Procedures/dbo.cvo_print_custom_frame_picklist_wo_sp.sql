SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[cvo_print_custom_frame_picklist_wo_sp] @order_no INT, @order_ext INT
AS
BEGIN
	-- Is order on a status of New
	IF NOT EXISTS(SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status = 'N')
	BEGIN
		RETURN
	END
	
	-- If order is already printed, drop out
	IF EXISTS(SELECT 1 FROM dbo.CVO_orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND flag_print = 2) 
	BEGIN
		RETURN
	END

	-- START v1.1
	-- If there are custom frame lines on the order which aren't hard allocated then drop out
	IF EXISTS (SELECT 1 FROM dbo.cvo_ord_list a LEFT JOIN tdc_soft_alloc_tbl b ON a.order_no = b.order_no AND a.order_ext = b.order_ext AND a.line_no = b.line_no AND b.order_type = 'S'
					WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND a.is_customized = 'S' AND b.line_no IS NULL)
	BEGIN
		RETURN
	END
	/*
	-- If order isn't hard allocated then drop out
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND [status] = -2)
	BEGIN
		RETURN
	END
	*/
	-- END v1.1

	-- If order contains a custom frame then print pick ticket and works order
	IF EXISTS(SELECT 1 FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND is_customized = 'S') 
	BEGIN
		
		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
		BEGIN
			
			IF (OBJECT_ID('tempdb..#PrintData') IS NOT NULL) 
				DROP TABLE #PrintData

			CREATE TABLE #PrintData 
			(row_id			INT IDENTITY (1,1)	NOT NULL
			,data_field		VARCHAR(300)		NOT NULL
			,data_value		VARCHAR(300)			NULL)
			
			EXEC CVO_disassembled_frame_sp @order_no, @order_ext
			
			EXEC CVO_disassembled_inv_adjust_sp @order_no, @order_ext
				
			EXEC CVO_disassembled_print_inv_adjust_sp @order_no, @order_ext		
				
			UPDATE	cvo_orders_all 
			SET		flag_print = 2 
			WHERE	order_no = @order_no 
			AND		 ext = @order_ext

			-- START v1.2
			INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
			SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
					'STATUS:N/PRINT WORKS ORDER'
			FROM	orders_all a (NOLOCK)
			JOIN	cvo_orders_all b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.ext = b.ext
			WHERE	a.order_no = @order_no
			AND		a.ext = @order_ext
			-- END v1.2		

			EXEC dbo.cvo_print_pick_ticket_sp @order_no, @order_ext

			-- START v1.2
			INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
			SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'PICK TICKET' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
					'STATUS:Q;'
			FROM	orders_all a (NOLOCK)
			JOIN	cvo_orders_all b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.ext = b.ext
			WHERE	a.order_no = @order_no
			AND		a.ext = @order_ext
			-- END v1.2

		END 				
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_print_custom_frame_picklist_wo_sp] TO [public]
GO
