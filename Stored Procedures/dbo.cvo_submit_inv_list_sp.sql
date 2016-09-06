SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC cvo_submit_inv_list_sp 'INV0069464,INV0047568,INV0047569,INV0049954'
-- EXEC cvo_submit_inv_list_sp 'INV0069464'
-- EXEC cvo_submit_inv_list_sp 'INV0069464,CRAP,INV0047568'
-- select * from cvo_email_ship_confirmation
-- delete cvo_email_ship_confirmation

CREATE PROC [dbo].[cvo_submit_inv_list_sp] @inv_list varchar(255) 
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@doc_ctrl_num	varchar(16),
			@order_no		int,
			@order_ext		int,
			@pos			int,		
			@ret_msg		varchar(510),
			@submit_msg		varchar(255),
			@error_msg		varchar(255),
			@row_id			int

	-- Processing
	WHILE (1 = 1)
	BEGIN

		SET @pos = CHARINDEX(',',@inv_list)

		IF (@pos = 0)
		BEGIN
			SET @doc_ctrl_num = @inv_list

			SET @order_no = 0
			SELECT	@order_no = order_no,
					@order_ext = order_ext
			FROM	orders_invoice (NOLOCK)
			WHERE	doc_ctrl_num = @doc_ctrl_num


			IF (@order_no IS NULL OR @order_no = 0)
			BEGIN
				IF (@error_msg IS NULL)
				BEGIN
					IF (@doc_ctrl_num <> '')
						SET @error_msg = 'The following invoices have not been submitted.' + CHAR(13) + CHAR(10) + ISNULL(@doc_ctrl_num,'')
				END
				ELSE
				BEGIN
					SET @error_msg = @error_msg + CHAR(13) + CHAR(10) + @doc_ctrl_num 
				END
			END
			ELSE
			BEGIN

				INSERT	dbo.cvo_email_ship_confirmation (order_no, order_ext, email_address, email_sent, invoice_no, doc_ctrl_num, etype)
				SELECT	a.order_no, a.ext, CASE WHEN ISNULL(a.email_address,'') = '' THEN c.contact_email ELSE a.email_address END, 0, b.invoice_no, d.doc_ctrl_num, 1
				FROM	cvo_orders_all a (NOLOCK)
				JOIN	orders_all b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.ext = b.ext
				JOIN	armaster_all c (NOLOCK)
				ON		b.cust_code = c.customer_code
				JOIN	orders_invoice d (NOLOCK)
				ON		a.order_no = d.order_no
				AND		a.ext = d.order_ext
				WHERE	a.order_no = @order_no
				AND		a.ext = @order_ext
				AND		c.address_type = CASE WHEN b.ship_to = '' THEN 0 ELSE 1 END
				AND		c.ship_to_code = CASE WHEN b.ship_to = '' THEN c.ship_to_code ELSE b.ship_to END 

				SELECT @row_id = @@IDENTITY

				IF EXISTS (SELECT 1 FROM dbo.cvo_email_ship_confirmation WHERE row_id = @row_id AND email_address IS NULL)
				BEGIN
					DELETE dbo.cvo_email_ship_confirmation WHERE row_id = @row_id
					IF (@error_msg IS NULL)
					BEGIN
						IF (@doc_ctrl_num <> '')
							SET @error_msg = 'The following invoices have not been submitted.' + CHAR(13) + CHAR(10) + ISNULL(@doc_ctrl_num,'') + ' -  No email address'
					END
					ELSE
					BEGIN
						SET @error_msg = @error_msg + CHAR(13) + CHAR(10) + @doc_ctrl_num + ' -  No email address'
					END					
				END
				ELSE
				BEGIN
					IF (@submit_msg IS NULL)
					BEGIN
						SET @submit_msg = 'The following invoices have been submitted.' + CHAR(13) + CHAR(10) + @doc_ctrl_num
					END
					ELSE
					BEGIN
						SET @submit_msg = @submit_msg + CHAR(13) + CHAR(10) + @doc_ctrl_num
					END
				END

			END

			BREAK
		END
		ELSE
		BEGIN

			SET @doc_ctrl_num = SUBSTRING(@inv_list, 1, @pos - 1)
			SET @inv_list = SUBSTRING(@inv_list, @pos + 1, LEN(@inv_list) - @pos + 1)

			SET @order_no = 0
			SELECT	@order_no = order_no,
					@order_ext = order_ext
			FROM	orders_invoice (NOLOCK)
			WHERE	doc_ctrl_num = @doc_ctrl_num

			IF (@order_no IS NULL OR @order_no = 0)
			BEGIN
				IF (@error_msg IS NULL)
				BEGIN
					IF (@doc_ctrl_num <> '')
						SET @error_msg = 'The following invoices have not been submitted.' + CHAR(13) + CHAR(10) + ISNULL(@doc_ctrl_num,'')
				END
				ELSE
				BEGIN
					SET @error_msg = @error_msg + CHAR(13) + CHAR(10) + @doc_ctrl_num 
				END
			END
			ELSE
			BEGIN

				INSERT	dbo.cvo_email_ship_confirmation (order_no, order_ext, email_address, email_sent, invoice_no, doc_ctrl_num, etype)
				SELECT	a.order_no, a.ext, CASE WHEN ISNULL(a.email_address,'') = '' THEN c.contact_email ELSE a.email_address END, 0, b.invoice_no, d.doc_ctrl_num, 1
				FROM	cvo_orders_all a (NOLOCK)
				JOIN	orders_all b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.ext = b.ext
				JOIN	armaster_all c (NOLOCK)
				ON		b.cust_code = c.customer_code
				JOIN	orders_invoice d (NOLOCK)
				ON		a.order_no = d.order_no
				AND		a.ext = d.order_ext
				WHERE	a.order_no = @order_no
				AND		a.ext = @order_ext
				AND		c.address_type = CASE WHEN b.ship_to = '' THEN 0 ELSE 1 END
				AND		c.ship_to_code = CASE WHEN b.ship_to = '' THEN c.ship_to_code ELSE b.ship_to END 

				SELECT @row_id = @@IDENTITY

				IF EXISTS (SELECT 1 FROM dbo.cvo_email_ship_confirmation WHERE row_id = @row_id AND email_address IS NULL)
				BEGIN
					DELETE dbo.cvo_email_ship_confirmation WHERE row_id = @row_id
					IF (@error_msg IS NULL)
					BEGIN
						IF (@doc_ctrl_num <> '')
							SET @error_msg = 'The following invoices have not been submitted.' + CHAR(13) + CHAR(10) + ISNULL(@doc_ctrl_num,'') + ' -  No email address'
					END
					ELSE
					BEGIN
						SET @error_msg = @error_msg + CHAR(13) + CHAR(10) + @doc_ctrl_num + ' -  No email address'
					END					
				END
				ELSE
				BEGIN
					IF (@submit_msg IS NULL)
					BEGIN
						SET @submit_msg = 'The following invoices have been submitted.' + CHAR(13) + CHAR(10) + @doc_ctrl_num
					END
					ELSE
					BEGIN
						SET @submit_msg = @submit_msg + CHAR(13) + CHAR(10) + @doc_ctrl_num
					END
				END
			END
		END
	END

	-- Return Message
	IF (@error_msg IS NULL)
	BEGIN
		SET @ret_msg = ISNULL(@submit_msg,'No Data Submitted') + CHAR(13) + CHAR(10) + ISNULL(@error_msg,'')
	END
	ELSE
	BEGIN
		SET @ret_msg = ISNULL(@submit_msg,'') + CHAR(13) + CHAR(10) + ISNULL(@error_msg,'')
	END
		
	SELECT	@ret_msg

END
GO
GRANT EXECUTE ON  [dbo].[cvo_submit_inv_list_sp] TO [public]
GO
