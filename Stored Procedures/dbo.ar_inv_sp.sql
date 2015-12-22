SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                










































































































































































































































































































  



					  

























































 


























































































































































































































































































CREATE PROC [dbo].[ar_inv_sp] @batch_ctrl_num varchar( 16 )
AS
BEGIN

DECLARE
	@comp_ctry_code	varchar(3),
	@eucomp_flag	smallint,
	@country_code	varchar(3),
	@saved		smallint,
	@trx_ctrl_num	varchar(16),
	@order_ctrl_num	varchar(16),
	@customer_code	varchar(8),
	@ship_to_code	varchar(8),
	@date_applied	int,
	@nat_cur_code	varchar(8),
	@freight_code	varchar(8),
	@fob_code	varchar(8),
	@rate_type	varchar(8),
	@is_input_exist	smallint
DECLARE
	@location_code	varchar(8),
	@line_desc	varchar(60),
	@item_code	varchar(30),
	@qty_item	float,
	@total_amt_nat	float,
	@amt_nat	float,
	@is_detail_freight	smallint,
	@amt_freight	float,
	@zone_code	varchar(8),
	@unit_code	varchar(10)
DECLARE
	@ctrl_int	int,
	@ext_int	int,
	@ctrl_str	varchar(16),
	@ext_str	varchar(20),
	@alt_ctrl_str	varchar(16)
DECLARE
	@po_ctrl_num	varchar(16),
	@vend_order_num	varchar(20),
	@vendor_code	varchar(12),
	@pay_to_code	varchar(8)
DECLARE
	@xfer_no	int,
	@from_loc	varchar(8),
	@to_loc		varchar(8),
	@apply_date	datetime,
	@routing	varchar(20)
DECLARE
	@return_code	smallint,
	@src_trx_id	varchar(4),
	@src_ctrl_num	varchar(16),
	@src_line_id	int,
	@prev_key	varchar(128),
	@key	varchar(128),
	@prev_line_id	int,
	@locations_exists int 	








	IF EXISTS (SELECT name FROM sysobjects WHERE name = "locations")
	  select @locations_exists = 1
	ELSE
	  select @locations_exists = 0











	SELECT @comp_ctry_code = country_code from glco (nolock)
	SELECT @eucomp_flag = 0
	SELECT @eucomp_flag = 1 WHERE @comp_ctry_code 
	IN (SELECT country_code FROM gl_glctry (nolock))

	SET ROWCOUNT 1

	

	BEGIN TRANSACTION

		SELECT @prev_key = ""










































		IF EXISTS (SELECT name FROM sysobjects WHERE name = 'orders_invoice')        
			SELECT @key = STR(h.trx_type, 4) + CONVERT(char(16), h.doc_ctrl_num),
				@trx_ctrl_num = h.doc_ctrl_num,
				@order_ctrl_num = h.order_ctrl_num,
				@customer_code = h.customer_code,
				@ship_to_code = h.ship_to_code,
				@date_applied = h.date_applied,
				@nat_cur_code = h.nat_cur_code,
				@freight_code = h.freight_code,
				@fob_code = h.fob_code,
				@amt_freight = h.amt_freight,
				@zone_code = h.dest_zone_code,
				@country_code = c.country_code,
				@rate_type = h.rate_type_home,
				@total_amt_nat = h.amt_gross - h.amt_discount
			FROM #artrx_work h, armaster c (nolock)
			WHERE h.trx_type = 2031
			AND	batch_code = @batch_ctrl_num
			AND h.customer_code = c.customer_code
			AND h.ship_to_code = c.ship_to_code
			AND c.country_code IN
			(SELECT country_code FROM gl_glctry (nolock))
			AND h.doc_ctrl_num IN
				(SELECT doc_ctrl_num FROM orders_invoice (nolock))
			ORDER BY h.trx_type, h.doc_ctrl_num
	    








		WHILE @@rowcount > 0
		BEGIN
			

			SELECT @src_trx_id = "", @src_ctrl_num = ""

			

			EXEC @return_code = ar_setarhdr_sp
				@trx_ctrl_num,
				@order_ctrl_num,
				1,
				0, @customer_code,
				0, @ship_to_code,
				0, @date_applied,
				0, @nat_cur_code,
				0, @freight_code,
				0, @fob_code,
				0, @rate_type,
				@src_trx_id	OUTPUT,
				@src_ctrl_num	OUTPUT,
				@is_input_exist	OUTPUT

			IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101
			BEGIN
				ROLLBACK TRANSACTION
				RETURN @return_code
			END

			

			SELECT @saved = 0
			SELECT @prev_line_id = 0





			IF  @locations_exists = 1
			BEGIN
				SELECT @src_line_id = d.sequence_id,
					@qty_item = d.qty_shipped,
					@amt_nat  = d.extended_price,
					@location_code = d.location_code,
					@item_code = d.item_code,
					@line_desc = d.line_desc,
					@unit_code = d.unit_code
				FROM artrxcdt d (nolock), locations l (nolock)
				WHERE d.trx_type = 2031
				AND d.doc_ctrl_num = @trx_ctrl_num
				AND ((d.location_code = ""
					AND @eucomp_flag = 1
					AND @comp_ctry_code <> @country_code)
				OR (d.location_code = l.location
					AND l.country_code <> @country_code
					AND l.country_code IN
						(SELECT country_code FROM gl_glctry (nolock) )))
				ORDER BY d.sequence_id
			END
			ELSE
			BEGIN
				SELECT @src_line_id = d.sequence_id,
					@qty_item = d.qty_shipped,
					@amt_nat  = d.extended_price,
					@location_code = d.location_code,
					@item_code = d.item_code,
					@line_desc = d.line_desc,
					@unit_code = d.unit_code
				FROM artrxcdt d (nolock)
				WHERE d.trx_type = 2031
				AND d.doc_ctrl_num = @trx_ctrl_num
				AND ( @eucomp_flag = 1 AND @comp_ctry_code <> @country_code)
				ORDER BY d.sequence_id
			END



			WHILE @@rowcount > 0
			BEGIN
				EXEC @return_code = gl_setarapdet_sp
					@src_trx_id,
					@src_ctrl_num,
					@src_line_id,
					@total_amt_nat,
					0, @customer_code,
					0, @ship_to_code,
					0, @location_code,
					0, @item_code,
					0, @line_desc,
					0, @qty_item,
					0, @amt_nat,
					0,
					0, @amt_freight,
					0, @zone_code,
					0, @unit_code

				IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101
				BEGIN
					ROLLBACK TRANSACTION
					RETURN @return_code
				END

				SELECT @saved = @saved + 1
				SELECT @prev_line_id = @src_line_id




				IF  @locations_exists = 1
				BEGIN
					SELECT @src_line_id = d.sequence_id,
						@qty_item = d.qty_shipped,
						@amt_nat  = d.extended_price,
						@location_code = d.location_code,
						@item_code = d.item_code,
						@line_desc = d.line_desc,
						@unit_code = d.unit_code
					FROM artrxcdt d (nolock), locations l (nolock)
					WHERE d.trx_type = 2031
					AND d.doc_ctrl_num = @trx_ctrl_num
					AND @prev_line_id < d.sequence_id
					AND ((d.location_code = ""
						AND @eucomp_flag = 1
						AND @comp_ctry_code <> @country_code)
					OR (d.location_code = l.location
						AND l.country_code <> @country_code
						AND l.country_code IN
							(SELECT country_code FROM gl_glctry (nolock))))
					ORDER BY d.sequence_id
				END
				ELSE
				BEGIN
					SELECT @src_line_id = d.sequence_id,
						@qty_item = d.qty_shipped,
						@amt_nat  = d.extended_price,
						@location_code = d.location_code,
						@item_code = d.item_code,
						@line_desc = d.line_desc,
						@unit_code = d.unit_code
					FROM artrxcdt d (nolock)
					WHERE d.trx_type = 2031
					AND d.doc_ctrl_num = @trx_ctrl_num
					AND @prev_line_id < d.sequence_id
					AND (@eucomp_flag = 1 AND @comp_ctry_code <> @country_code)
					ORDER BY d.sequence_id
				END
			END

			

			IF @saved > 0
			BEGIN
				SELECT @ctrl_int = 0,              @ext_int = 0,
					@ctrl_str = @trx_ctrl_num, @ext_str = @order_ctrl_num, @alt_ctrl_str = ''

				EXEC @return_code = gl_saveinp_sp
					@src_trx_id, @src_ctrl_num, @ctrl_int, @ext_int, @ctrl_str, @ext_str, @alt_ctrl_str

				IF @return_code < 0 OR @return_code = 8100 OR @return_code = 8101
				BEGIN
					ROLLBACK TRANSACTION
					RETURN @return_code
				END
			END
			ELSE
			BEGIN
				DELETE FROM gl_glinphdr WHERE
					(@trx_ctrl_num = src_doc_num AND src_trx_id = "2031") OR
					(@order_ctrl_num = src_doc_num AND src_trx_id = "OEIV")
			END


			

			EXEC @return_code = gl_cleaninp_sp @src_trx_id, @src_ctrl_num

			IF @return_code <> 0
			BEGIN
				ROLLBACK TRANSACTION
				RETURN @return_code
			END

			SELECT @prev_key = @key







































			IF EXISTS (SELECT name FROM sysobjects WHERE name = 'orders_invoice')							
				SELECT @key = STR(h.trx_type, 4) + CONVERT(char(16), h.doc_ctrl_num),
					@trx_ctrl_num = h.doc_ctrl_num,
					@order_ctrl_num = h.order_ctrl_num,
					@customer_code = h.customer_code,
					@ship_to_code = h.ship_to_code,
					@date_applied = h.date_applied,
					@nat_cur_code = h.nat_cur_code,
					@freight_code = h.freight_code,
					@fob_code = h.fob_code,
					@amt_freight = h.amt_freight,
					@zone_code = h.dest_zone_code,
					@country_code = c.country_code,
					@rate_type = h.rate_type_home,
					@total_amt_nat = h.amt_gross - h.amt_discount
				FROM #artrx_work h, armaster c (nolock)
				WHERE h.trx_type = 2031
				AND	batch_code = @batch_ctrl_num			
				AND h.customer_code = c.customer_code
				AND h.ship_to_code = c.ship_to_code
				AND c.country_code IN
					(SELECT country_code FROM gl_glctry (nolock))
				AND @prev_key < STR(h.trx_type, 4) + CONVERT(char(16), h.doc_ctrl_num)	
				AND h.doc_ctrl_num IN
					(SELECT doc_ctrl_num FROM orders_invoice (nolock))
				ORDER BY h.trx_type, h.doc_ctrl_num











		END
	COMMIT TRANSACTION

	SET ROWCOUNT 0
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ar_inv_sp] TO [public]
GO
