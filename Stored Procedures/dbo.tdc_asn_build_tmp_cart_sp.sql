SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************/
/* Name:	tdc_asn_build_tmp_cart_sp			*/
/*								*/
/* Input:							*/
/*	carton	-	Carton Number				*/
/*								*/
/* Output:        						*/
/*	None							*/
/*								*/
/* Description:							*/
/*	This SP will be used to add records to the ASN carton   */
/*	detail temp. table.  This SP will only be called for    */
/*      cartons that have been ship confirmed.			*/
/*								*/
/* Revision History:						*/
/* 	Date		Who	Description			*/
/*	----		---	-----------			*/
/* 	08/05/1999	CAC	Initial				*/
/*								*/
/****************************************************************/

CREATE PROCEDURE [dbo].[tdc_asn_build_tmp_cart_sp](@carton_no int)
AS

	/* Declare local variables */
	DECLARE @err 		int
	DECLARE @order_no	int
	DECLARE @order_ext	int
	DECLARE @line_no	int
	DECLARE @part_no	varchar(30)
	DECLARE @carton_packed	decimal(20, 8)
	DECLARE @ordered	decimal(20, 8)
	DECLARE @picked		decimal(20, 8)


	/* Initialize the error code to no errors */
	SELECT @err = 0

	/*
	 * Create cursor to scroll thru all high level parent records for the ASN. 
	 */
	DECLARE cart_cursor CURSOR FOR
	 SELECT order_no, order_ext, line_no, part_no, convert(decimal(20, 8), sum(pack_qty)) 
	   FROM tdc_carton_detail_tx (NOLOCK)
	  WHERE carton_no = @carton_no
	  GROUP BY order_no, order_ext, line_no, part_no
	  ORDER BY order_no, order_ext, line_no

	OPEN cart_cursor

	FETCH NEXT FROM cart_cursor 
		INTO @order_no, @order_ext, @line_no, @part_no, @carton_packed

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		/*
		 * Get Order information.
		 */
		SELECT @ordered = ordered, @picked = shipped
		  FROM ord_list
		 WHERE order_no = @order_no
		   AND order_ext = @order_ext
		   AND line_no = @line_no

		INSERT INTO #tdc_asn_cart_det
			(carton, 	order_no, 	order_ext, 
			 line_no,	part_no,	ordered,
			 picked,	carton_packed)
		VALUES
			(@carton_no,	@order_no,	@order_ext,
			 @line_no,	@part_no,	@ordered,
			 @picked,	@carton_packed)
	
		FETCH NEXT FROM cart_cursor 
			INTO @order_no, @order_ext, @line_no, @part_no, @carton_packed
	END

	CLOSE cart_cursor
	DEALLOCATE cart_cursor

	RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_build_tmp_cart_sp] TO [public]
GO
