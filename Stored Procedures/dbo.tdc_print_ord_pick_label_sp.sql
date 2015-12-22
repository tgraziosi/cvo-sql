SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_ord_pick_label_sp](
			@order_no   int,
			@order_ext  int,
			@part_no    varchar(24),
			@lot_ser    varchar(24),
			@qty        varchar(20),
			@station_id varchar(20),
			@user_id    varchar(50))
AS

-- Remove the '0' after the '.'
EXEC tdc_trim_zeros_sp @qty OUTPUT

DECLARE	@cust_code   varchar(50),
	@cust_name   varchar(50),
	@cust_po     varchar(30),
	@description varchar(275),
	@header_add_note varchar (255),
	@return_value	int

SELECT @cust_code = cust_code, @cust_po = cust_po      
  FROM orders (NOLOCK) 
 WHERE order_no  = @order_no
   AND ext       = @order_ext

SELECT @cust_name = customer_name
  FROM arcust (NOLOCK)
 WHERE customer_code = @cust_code

IF EXISTS(SELECT * FROM ord_list(NOLOCK) 
	   WHERE order_no   = @order_no
             AND order_ext  = @order_ext
	     AND part_no    = @part_no
	     AND part_type != 'C')
BEGIN
	SELECT TOP 1 @description = [description]
	  FROM ord_list(NOLOCK) 
	 WHERE order_no   = @order_no
           AND order_ext  = @order_ext
	   AND part_no    = @part_no
END
ELSE
BEGIN
	SELECT TOP 1 @description = [description]
	  FROM ord_list_kit(NOLOCK) 
	 WHERE order_no   = @order_no
           AND order_ext  = @order_ext
	   AND part_no	  = @part_no
END

EXEC tdc_parse_string_sp @description, @description output	

-- Order header additional note
SELECT @header_add_note = CAST(note AS varchar(255))
  FROM notes (NOLOCK)
 WHERE code_type = 'O'
   AND code      = @order_no           
   AND line_no   = 0

IF @header_add_note IS NULL SET @header_add_note = ''

EXEC tdc_parse_string_sp @header_add_note, @header_add_note OUTPUT

INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_NO', 	  	CAST(@order_no  AS varchar(10)))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_EXT',   	CAST(@order_ext AS varchar(4)))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PART_NO', 	  	@part_no)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOT_SER', 	  	@lot_ser)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_QTY', 	  	@qty)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_CODE',   	ISNULL(@cust_code, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_NAME',   	ISNULL(@cust_name, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_PO', 	  	ISNULL(@cust_po,   	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DESCRIPTION', 	ISNULL(@description,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_HEADER_ADD_NOTE', 	ISNULL(@header_add_note,''))

IF (@@ERROR <> 0 )
BEGIN
	RAISERROR ('Insert into #PrintData Failed', 16, 1)					
	RETURN
END

-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----
EXEC @return_value = tdc_print_label_sp 'PPS', 'OPICK', 'VB', @station_id

-- IF label hasn't been set up for the station id, try finding a record for the user id
IF @return_value != 0
BEGIN
	EXEC @return_value = tdc_print_label_sp 'PPS', 'OPICK', 'VB', @user_id
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_print_ord_pick_label_sp] TO [public]
GO
