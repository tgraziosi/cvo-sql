SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			CVO_pad_print_ticket_sp		
Project ID:		Issue 690
Type:			Stored Proc
Description:	Pads pick tickets with blank lines to split cartons over pages
Developer:		Chris Tyler

History
-------
v1.0	26/07/12	CT	Original version
v1.1	20/08/12	CT	Fix bug in calculating correct number of blank lines to add
*/

CREATE PROC [dbo].[CVO_pad_print_ticket_sp] (@reqd_lines INT, @next_line INT)
AS
BEGIN

	DECLARE @line INT --v1.1

	SEt @line = 1 -- v1.1
	WHILE @line <= @reqd_lines	-- v1.1
	BEGIN

		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LIST_PRICE_'      + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_GROSS_PRICE_'     + RTRIM(CAST(@next_line AS char(4))) + ',' + '')   
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_NET_PRICE_'       + RTRIM(CAST(@next_line AS char(4))) + ',' + '')   
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DISCOUNT_AMOUNT_' + RTRIM(CAST(@next_line AS char(4))) + ',' + '')   		  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DISCOUNT_PCT_'	 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')   		  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LINE_NO_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DISPLAY_LINE_NO_' + RTRIM(CAST(@next_line AS char(4))) + ',' + '') 
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_PART_TYPE_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')     
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_UOM_'			 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DESCRIPTION_'     + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DETAIL_ADD_NOTE_' + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ORD_QTY_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_TOPICK_'			 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_PART_NO_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LOT_SER_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_BIN_NO_'			 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_NOTE_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_TRAN_ID_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DEST_BIN_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SKU_'			 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_HEIGHT_'			 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_WIDTH_'			 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CUBIC_FEET_'      + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LENGTH_'			 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CMDTY_CODE_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_WEIGHT_'			 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SO_QTY_INCR_'	 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CATEGORY_1_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CATEGORY_2_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CATEGORY_3_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CATEGORY_4_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CATEGORY_5_'		 + RTRIM(CAST(@next_line AS char(4))) + ',' + '')  
	
		SET @next_line = @next_line + 1
		SET @line = @line + 1  -- v1.1  
	END
END

GO
GRANT EXECUTE ON  [dbo].[CVO_pad_print_ticket_sp] TO [public]
GO
