SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CT 02/12/2013 - Create a credit return from sales order upload
-- v1.1 CT 17/01/2014 - Issue #1356 - Add original order number as a note
-- v1.2 TG 6/26/14 - put the HS order number in user_def_fld4
-- v1.3	CT 17/07/2014 - Issue #1493 - default credit return to auto receive	
-- v1.4	CT 15/10/2014 - If CVO_create_upload_credit_return_price_sp returns std pricing required for credit line, set list price = NULL to force code to recalc it
-- v1.5 CT 10/12/2014 - Issue #1505 - New field for email address, contained in upload file
-- v1.6 CT 18/02/2015 - Issue #1526 - Expand promo kits
-- v1.7 CB 05/09/2016 - Use returns account

CREATE PROC [dbo].[CVO_create_upload_credit_return_sp] (@SPID INT, @hold SMALLINT)  
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@cust_code				VARCHAR(10),
			@ship_to				VARCHAR(10),
			@location				VARCHAR(10),
			@ra_in					VARCHAR(30),
			@ra						VARCHAR(15),
			@new_order_no			INT,
			@note					VARCHAR(255),
			@salesperson_name		VARCHAR(40),
			@hold_reason			VARCHAR(10),
			@return_code			VARCHAR(40),
			@charpos				INT,
			@chartest				CHAR(1),
			@ship_via_code			VARCHAR(8),
			@rec_id					INT,
			@part_no				VARCHAR(30),
			@quantity				DECIMAL(20,8),
			@line_no				INT,
			@price					DECIMAL(20,8),
			@price_type				CHAR(1),
			@std_pricing			SMALLINT,
			@list_price				DECIMAL(20,8),
			@amt_disc				DECIMAL(20,8),
			@who_entered			VARCHAR(20),
			@ship_complete_flag		SMALLINT,
			@so_priority_code		CHAR(1),
			@tax_code				VARCHAR(8),
			@ship_to_name			VARCHAR(40),
			@ship_to_add_1			VARCHAR(40),
			@ship_to_add_2			VARCHAR(40),
			@ship_to_add_3			VARCHAR(40),
			@ship_to_add_4			VARCHAR(40),
			@ship_to_add_5			VARCHAR(40),
			@ship_to_city			VARCHAR(40),
			@ship_to_state			VARCHAR(40),
			@ship_to_zip			VARCHAR(15),
			@ship_to_country		VARCHAR(40),
			@terms_code				VARCHAR(8),       
			@fob_code				VARCHAR(8),
			@territory_code			VARCHAR(8),
			@salesperson_code		VARCHAR(8),  
			@trade_disc_percent		FLOAT,
			@short_name				VARCHAR(10), 
			@nat_cur_code			VARCHAR(8),     
			@one_cur_cust			SMALLINT,
			@rate_type_home			VARCHAR(8),   
			@rate_type_oper			VARCHAR(8),
			@remit_code				VARCHAR(10),     	
			@forwarder_code			VARCHAR(10),
			@freight_to_code		VARCHAR(10),  
			@dest_zone_code			VARCHAR(8),
			@special_instr			VARCHAR(255),
			@payment_code			VARCHAR(8),     
			@posting_code			VARCHAR(8),
			@price_level			CHAR(1),      
			@price_code				VARCHAR(8),
			@contact_name			VARCHAR(40),
			@contact_phone			VARCHAR(30),
			@status_type			SMALLINT,
			@error					INT, 
			@home_rate				FLOAT, 
			@oper_rate				FLOAT,
			@apply_date				INT,
			@consolidated_invoices	INT,
			@country_code			VARCHAR(3),
			@plevel					CHAR(1), 
			@new_user_code			VARCHAR(8),
			@freight_allow_type		VARCHAR(10),
			@orig_order_no			VARCHAR(40), -- v1.1
			@email_address			VARCHAR(255) -- v1.2

	-- Create temporary table
	CREATE TABLE #std_price (
		plevel CHAR(1), 
		price decimal(20,8), 
		next_qty decimal(20,8),  
		next_price decimal(20,8), 
		promo_price decimal(20,8), 
		sales_comm decimal(20,8),  
		qloop INT, 
		quote_level INT, 
		quote_curr VARCHAR(10))

	-- If no records in working tables then delete
	IF NOT EXISTS(SELECT 1 FROM dbo.cvo_upload_credit_return_hdr (NOLOCK) WHERE spid = @SPID)
	BEGIN
		SELECT -1
		RETURN -1
	END

	IF NOT EXISTS(SELECT 1 FROM dbo.cvo_upload_credit_return_det (NOLOCK) WHERE spid = @SPID)
	BEGIN
		SELECT -2
		RETURN -2
	END

	-- Get defaults from config
	SELECT @hold_reason = value_str FROM dbo.config (NOLOCK) WHERE flag = 'CR_UPLOAD_HOLD_RES'
	SELECT @return_code = value_str FROM dbo.config (NOLOCK) WHERE flag = 'CR_UPLOAD_RET_CODE' 

	-- Validate defaults
	IF NOT EXISTS (SELECT 1 FROM dbo.po_retcode (NOLOCK) WHERE return_code = @return_code and void ='N')
	BEGIN
		SELECT -3
		RETURN -3
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_crhold (NOLOCK) WHERE hold_code = @hold_reason )
	BEGIN
		SELECT -4
		RETURN -4
	END
	
	-- Load header details
	SELECT
		@cust_code = cust_code,
		@ship_to = ship_to,
		@location = location,
		@ra_in = ra,
		@who_entered = who_entered,
		@orig_order_no = orig_order_no, -- v1.1
		@email_address = email_address -- v1.2
	FROM
		dbo.cvo_upload_credit_return_hdr (NOLOCK) 
	WHERE 
		spid = @SPID

	-- Format RA#
	IF ISNULL(@ra_in, '') = ''
	BEGIN
		SET @ra = ''
	END
	ELSE
	BEGIN

		-- 1. Remove dashes
		SET @ra_in = REPLACE(@ra_in,'-','')

		-- 2. RA cannot be less than 4 digits
		IF LEN(@ra_in) < 4 
		BEGIN
			SELECT -5
			RETURN -5
		END

		-- 3. RA cannot be longer than 15 digits
		IF LEN(@ra_in) > 15
		BEGIN
			SELECT -6
			RETURN -6
		END

		-- 4. Must only by numeric characters
		SET @charpos = 1
		WHILE @charpos <= LEN(@ra_in)
		BEGIN
			-- Get next character
			SET @chartest = SUBSTRING(@ra_in,@charpos,1)
			
			-- Ensure it's a numeric
			IF CHARINDEX (@chartest,'0123456789') = 0
			BEGIN
				SELECT -7
				RETURN -7
			END

			SET @charpos = @charpos + 1
		END

		-- 5. Pad with zeros to make up to 15 characters
		IF LEN(@ra_in) < 15
		BEGIN
			SET @ra = LEFT(@ra_in,3) + RIGHT('000000000000' + RIGHT(@ra_in,(LEN(@ra_in) - 3)), 12)
		END
		ELSE
		BEGIN
			SET @ra = @ra_in
		END
	END

	-- START v1.6
	EXEC dbo.CVO_upload_credit_return_promo_kit_sp @SPID, @location
	-- END v1.6


	-- Credit return in USD
	SET @nat_cur_code = 'USD'
	SET @home_rate = 1
	SET @oper_rate = 1

	-- Get default freight allow type
	SELECT 
		@freight_allow_type = UPPER(value_str)
	FROM 
		dbo.config (NOLOCK) 
	WHERE 
		flag = 'FRTHTYPE'

	-- Get the next order number
	BEGIN TRAN
	UPDATE	dbo.next_order_num  
	SET		last_no = last_no + 1 
	COMMIT TRAN
	SELECT @new_order_no = last_no  
	FROM dbo.next_order_num

	-- Get customer details
	SELECT 
		@consolidated_invoices = consolidated_invoices,
		@ship_complete_flag = ship_complete_flag,
		@so_priority_code = so_priority_code,
		@tax_code = tax_code,
		@ship_to_name = address_name,
		@ship_to_add_1 = addr2,
		@ship_to_add_2 = addr3,
		@ship_to_add_3 = addr4,
		@ship_to_add_4 = addr5,
		@ship_to_add_5 = addr6,
		@ship_to_city = city,
		@ship_to_state = [state],
		@ship_to_zip = postal_code,
		@ship_to_country = country,
		@terms_code	= terms_code,       
		@fob_code = fob_code,
		@territory_code	= territory_code,
		@salesperson_code = salesperson_code,  
		@trade_disc_percent	= trade_disc_percent,
		@ship_via_code	= ship_via_code,   
		@short_name = short_name,
		@one_cur_cust = one_cur_cust,
		@rate_type_home = rate_type_home,   
		@rate_type_oper = rate_type_oper,
		@remit_code = remit_code,     	
		@forwarder_code = forwarder_code,
		@freight_to_code = freight_to_code,  
		@dest_zone_code	= dest_zone_code,
		@note = note,
		@special_instr = special_instr,
		@payment_code = payment_code,
		@posting_code = posting_code,
		@price_level = price_level,      
		@price_code = price_code,
		@contact_name = contact_name,
		@contact_phone = contact_phone,
		@status_type = status_type,
		@country_code = country_code,
		@ship_via_code = ship_via_code
	FROM
		dbo.armaster_all (NOLOCK)
	WHERE
		address_type = 0
		AND customer_code = @cust_code

	-- If there is a ship to then update with the details from there
	IF ISNULL(@ship_to,'') <> ''
	BEGIN
 
		SELECT 
			@so_priority_code = so_priority_code,
			@tax_code = tax_code,
			@ship_to_name = address_name,
			@ship_to_add_1 = addr2,
			@ship_to_add_2 = addr3,
			@ship_to_add_3 = addr4,
			@ship_to_add_4 = addr5,
			@ship_to_add_5 = addr6,
			@ship_to_city = city,
			@ship_to_state = [state],
			@ship_to_zip = postal_code,
			@ship_to_country = country,
			@terms_code	= terms_code,       
			@fob_code = CASE ISNULL(fob_code,'') WHEN '' THEN @fob_code ELSE fob_code END,
			@territory_code	= territory_code,
			@salesperson_code = salesperson_code,  
			@ship_via_code	= ship_via_code,   
			@short_name = short_name,
			@one_cur_cust = one_cur_cust,
			@remit_code = remit_code,     	
			--@forwarder_code = forwarder_code,
			@freight_to_code = freight_to_code,  
			@dest_zone_code	= dest_zone_code,
			@note = note,
			--@special_instr = special_instr,
			@price_level = price_level,      
			@contact_name = contact_name,
			@contact_phone = contact_phone,
			@status_type = status_type,
			@country_code = country_code,
			@ship_via_code = ship_via_code
		FROM
			dbo.armaster_all (NOLOCK)
		WHERE
			address_type = 1
			AND customer_code = @cust_code
			AND ship_to_code = @ship_to
	END
 
	-- Default terms to be NET30
	SET @terms_code = 'NET30'

	-- Create order note
	SELECT
		@salesperson_name = salesperson_name
	FROM
		dbo.arsalesp (NOLOCK)
	WHERE
		salesperson_code = @salesperson_code

	-- START v1.1
	IF ISNULL(@orig_order_no,'') <> ''
	BEGIN
		SET @note = 'Please reference Handshake order #' + @orig_order_no + CHAR(13) + CHAR(10) + 'Entered by ' + ISNULL(@salesperson_name, @salesperson_code)
	END
	ELSE
	BEGIN
		SET @note = 'Entered by ' + ISNULL(@salesperson_name, @salesperson_code)
	END
	-- END v1.1

	-- Begin transaction
	BEGIN TRAN	

	-- Create the order header
	INSERT INTO orders (order_no, ext, cust_code, ship_to, req_ship_date, sch_ship_date, date_entered, who_entered, [status], attention, 
						phone, terms, routing, total_invoice, salesperson, tax_perc, invoice_no, fob, freight, printed, discount, 
						label_no, ship_to_name, ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_add_4, ship_to_add_5, ship_to_city, ship_to_state, ship_to_zip, 
						ship_to_region, total_amt_order, tax_id, cash_flag, special_instr, [type], note, void, changed, remit_key, 
						forwarder_key, freight_to, sales_comm, freight_allow_pct, back_ord_flag, route_code, route_no, cr_invoice_no, location, total_tax, 
						total_discount, f_note, blanket, gross_sales, curr_factor, curr_key, freight_allow_type, bill_to_key, load_no, oper_factor, 
						tot_ord_tax, tot_ord_disc, tot_ord_freight, posting_code, rate_type_home, rate_type_oper, hold_reason, dest_zone_code, orig_no, orig_ext, 
						user_code, user_priority, user_category, organization_id, internal_so_ind, ship_to_country_cd
						, user_def_fld4 -- v1.2 TG
						 ) 
	SELECT				@new_order_no, 0, @cust_code, ISNULL(@ship_to,''), GETDATE(), GETDATE(), GETDATE(), @who_entered, CASE @hold WHEN 0 THEN 'N' ELSE 'A' END, @contact_name, 
						@contact_phone, @terms_code, @ship_via_code, 0, @salesperson_code, 0, 0, @fob_code, 0, 'N', 0, 
						0, @ship_to_name, @ship_to_add_1, @ship_to_add_2, @ship_to_add_3, @ship_to_add_4, @ship_to_add_5, @ship_to_city, @ship_to_state, @ship_to_zip,
						@territory_code, 0, @tax_code, 'N', @special_instr, 'C', @note, 'N', 'Y', 'CVO', 
						@forwarder_code, @freight_to_code, 0, 0, '0', '', 0, 0, @location, 0, 
						0, '', 'N', 0, @home_rate, @nat_cur_code, @freight_allow_type, @cust_code, 0, @oper_rate, 
						0, 0, 0, @posting_code, @rate_type_home, @rate_type_oper, CASE @hold WHEN 0 THEN '' ELSE @hold_reason END, @dest_zone_code, 0, 0, 
						CASE @hold WHEN 0 THEN '' ELSE 'USERHOLD' END, '', '', 'CVO', 0, @country_code
						, @orig_order_no -- v1.2 TG

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRAN
		SELECT -10
		RETURN -10
	END

	-- Update cvo_orders_all
	UPDATE 
		dbo.cvo_orders_all 
	SET 
		fee = NULL, 
		fee_type = 0, 
		fee_line = 0, 
		return_code = @return_code, 
		ra1 = CASE ISNULL(@ra,'') WHEN '' THEN NULL ELSE @ra END, 
		ra2 = NULL, 
		ra3 = NULL, 
		ra4 = NULL, 
		ra5 = NULL, 
		ra6 = NULL, 
		ra7 = NULL, 
		ra8 = NULL, 
		promo_id = NULL, 
		promo_level = NULL , 
		buying_group = '' ,
		-- START v1.3
		auto_receive = 1,
		--auto_receive = 0
		-- END v1.3
		-- START v1.5
		email_address = @email_address
		-- END v1.5
	WHERE 
		order_no = @new_order_no 
		AND ext =0 

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRAN
		SELECT -11
		RETURN -11
	END

	
	-- Write lines to credit return
	SET @rec_id = 0
	SET @line_no = 0
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@rec_id = rec_id,
			@part_no = part_no,
			@quantity = quantity
		FROM
			dbo.cvo_upload_credit_return_det (NOLOCK)
		WHERE
			spid = @spid
			AND rec_id > @rec_id
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		SET @line_no = @line_no + 1

		-- Pricing
		EXEC dbo.CVO_create_upload_credit_return_price_sp	@customer_code = @cust_code, 
															@part_no = @part_no, 
															@return_code = @return_code,
															@price = @price OUTPUT,
															@list_price	= @list_price OUTPUT,
															@price_level = @price_type OUTPUT,
															@std_pricing = @std_pricing	OUTPUT 
		
		-- Need to use standard pricing
		IF @std_pricing = 1
		BEGIN
			DELETE FROM #std_price
			INSERT INTO #std_price EXEC dbo.fs_get_price	@cust = @cust_code,
														@shipto = @ship_to,
														@clevel = '1',
														@pn = @part_no,
														@loc = @location,
														@plevel = '1',
														@qty = @quantity,
														@pct = 0,
														@curr_key = @nat_cur_code,
														@curr_factor = 1,
														@svc_agr = 'N'  
			
			SELECT
				@price = price,
				@price_type = plevel
			FROM
				#std_price

			-- START v1.4
			SET @list_price = NULL	
			-- END v1.4
		END

		-- If list price hasn't been returned then get it
		IF @list_price IS NULL
		BEGIN
				SELECT 	
					@list_price = b.price 
				FROM 	
					dbo.adm_inv_price a (NOLOCK)
				INNER JOIN		
					dbo.adm_inv_price_det b (NOLOCK)
				ON		
					a.inv_price_id = b.inv_price_id
				WHERE	
					a.part_no = @part_no
					AND b.p_level = 1
					AND a.active_ind = 1
		END

		-- Calculate discount amount
		SET @amt_disc = @list_price - @price

		INSERT INTO dbo.ord_list ( 
			order_no, order_ext, line_no, location, part_no, [description], time_entered, ordered, shipped, price, 
			price_type, [status], cost, who_entered, sales_comm, temp_price, cr_ordered, cr_shipped, discount, uom, 
			conv_factor, std_cost, cubic_feet, lb_tracking, labor, direct_dolrs, ovhd_dolrs, util_dolrs, qc_flag, reason_code, 
			taxable, part_type, qc_no, rejected, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, display_line, 
			back_ord_flag, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, service_agreement_flag, return_code, organization_id, [contract]) 
		SELECT 
			@new_order_no, 0, @line_no, b.location, a.part_no, a.[description], GETDATE(), 0, 0, @price, 
			@price_type, CASE @hold WHEN 0 THEN 'N' ELSE 'A' END, 0, @who_entered, 0, 0, @quantity, 0, 0, a.uom, 
			1, 0, a.cubic_feet, a.lb_tracking, 0, 0, 0, 0, a.qc_flag, 'RETURN', 
-- v1.7		a.taxable, a.[status], 0, 0, c.sales_acct_code, 0, @tax_code, @price, @price, @line_no, 
			a.taxable, a.[status], 0, 0, c.sales_return_code, 0, @tax_code, @price, @price, @line_no, -- v1.7
			'N', 0, 0, 0, 'N', @return_code, 'CVO', '' 
		FROM
			dbo.inv_master a (NOLOCK)
		INNER JOIN
			dbo.inv_list b (NOLOCK)
		ON
			a.part_no = b.part_no
		INNER JOIN 
			dbo.in_account c (NOLOCK)
		ON
			b.acct_code = c.acct_code
		WHERE
			a.part_no = @part_no
			AND b.location = @location
	
		IF (@@ERROR <> 0)
		BEGIN
			ROLLBACK TRAN
			SELECT -20
			RETURN -20
		END

		-- Update cvo_ord_list
		UPDATE 
			dbo.cvo_ord_list 
		SET 
			list_price = @list_price, 
			amt_disc = @amt_disc 
		WHERE 
			order_no = @new_order_no 
			AND order_ext = 0 
			AND line_no = @line_no
	
		IF (@@ERROR <> 0)
		BEGIN
			ROLLBACK TRAN
			SELECT -21
			RETURN -21
		END
	END

	-- Calculate totals
	EXEC dbo.fs_calculate_oetax_wrap @ord = @new_order_no, @ext = 0, @batch_call = 1 
	EXEC dbo.fs_updordtots @ordno = @new_order_no, @ordext = 0

	-- Commit transcation
	COMMIT TRAN

	-- Remove date from working tables
	DELETE FROM dbo.cvo_upload_credit_return_hdr WHERE spid = @SPID
	DELETE FROM dbo.cvo_upload_credit_return_det WHERE spid = @SPID

	SELECT @new_order_no
	RETURN @new_order_no
	

END
GO
GRANT EXECUTE ON  [dbo].[CVO_create_upload_credit_return_sp] TO [public]
GO
