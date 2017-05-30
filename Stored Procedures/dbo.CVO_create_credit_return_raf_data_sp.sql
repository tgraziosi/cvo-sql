SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CT 02/12/2013 - Create a credit return from sales order upload
-- v1.1 CT 10/12/2014 - Issue #1505 - If the credit return contains an email, use that instead.
-- v1.2 CB 12/09/2016 - #1613 - Custom kits in order upload
-- v1.3 CB 15/05/2017 - Return is not using the inv return flag from the return code

-- Selects 0 for success, -1 if tables not populated

CREATE PROC [dbo].[CVO_create_credit_return_raf_data_sp]	@SPID		INT, 
														@order_no	INT,
														@ext		INT  
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	DECLARE @cust_code		VARCHAR(10),
			@ship_to		VARCHAR(10),
			@customer_name	VARCHAR(40),
			@contact_name	VARCHAR(40),
			@contact_email	VARCHAR(255),
			@has_ship_to	SMALLINT

	SET @has_ship_to = 0

	-- Remove any data from archive table for this credit
	DELETE FROM dbo.cvo_raf_det_archive WHERE order_no = @order_no AND ext = @ext

	-- Clear report tables
	DELETE FROM cvo_raf_hdr WHERE spid = @SPID
	DELETE FROM cvo_raf_det WHERE spid = @SPID
	
	-- Get customer details
	SELECT 
		@cust_code = cust_code,
		@ship_to = ship_to
	FROM
		dbo.orders (NOLOCK)
	WHERE
		order_no = @order_no
		AND ext = @ext

	-- 2. If there is a ship then get details	
	IF ISNULL(@ship_to,'') <> ''
	BEGIN
		SELECT
			@customer_name = address_name,
			@contact_name = contact_name,
			@contact_email = contact_email
		FROM
			dbo.armaster_all a (NOLOCK)
		WHERE
			customer_code = @cust_code
			AND ship_to_code = @ship_to 
			AND address_type = 1

		SET @has_ship_to = 1
	END

	-- Load header details
	-- 1. Customer details
	INSERT INTO dbo.cvo_raf_hdr(
		spid,
		order_no,
		ext,
		customer_code,
		customer_name,
		contact_name,
		contact_email,
		ship_to_add_1,
		ship_to_add_2,
		ship_to_add_3,
		ship_to_add_4,
		ship_to_add_5)
	SELECT
		@spid,
		b.order_no,
		b.ext,
		a.customer_code,
		UPPER(CASE @has_ship_to WHEN 0 THEN a.address_name ELSE @customer_name END),
		UPPER(CASE @has_ship_to WHEN 0 THEN a.contact_name ELSE @contact_name END),
		UPPER(CASE @has_ship_to WHEN 0 THEN a.contact_email ELSE @contact_email END),
		UPPER(b.ship_to_add_1),
		UPPER(b.ship_to_add_2),
		UPPER(b.ship_to_add_3),
		UPPER(b.ship_to_add_4),
		UPPER(b.ship_to_add_5)
	FROM
		dbo.armaster_all a (NOLOCK)
	INNER JOIN
		dbo.orders b (NOLOCK)
	ON
		a.customer_code = b.cust_code
	WHERE
		a.customer_code = @cust_code
		AND a.address_type = 0
		AND b.order_no = @order_no
		AND b.ext = @ext

	IF @@ROWCOUNT <> 1
	BEGIN
		SELECT -1
		RETURN
	END

	-- START v1.1
	IF EXISTS (SELECT 1 FROM dbo.cvo_orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND ISNULL(email_address,'') <> '')
	BEGIN
		-- Pull email address from credit return
		UPDATE
			a
		SET
			contact_email = b.email_address
		FROM	
			dbo.cvo_raf_hdr a 
		INNER JOIN
			dbo.cvo_orders_all b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.ext = b.ext
		WHERE
			a.spid = @SPID
			AND b.order_no = @order_no
			AND b.ext = @ext
	END
	-- END v1.1

	-- Load line details
	INSERT INTO dbo.cvo_raf_det(
		spid,
		display_line,
		part_no,
		[description],
		quantity,
		upc_code)
	SELECT
		@spid,
		a.display_line,
		UPPER(a.part_no),
		a.[description],
		a.cr_ordered,
		ISNULL(b.upc,'')
	FROM
		dbo.ord_list a (NOLOCK)
	LEFT JOIN
		dbo.uom_id_code b (NOLOCK)
	ON
		a.part_no = b.part_no
	WHERE
		a.order_no = @order_no
		AND a.order_ext = @ext
		AND a.part_type IN ('P','C','N') -- v1.2 v1.3

	IF @@ROWCOUNT <= 0
	BEGIN
		SELECT -1
		RETURN
	END

	-- Load line details into archive
	INSERT INTO dbo.cvo_raf_det_archive(
		order_no,
		ext,
		line_no,
		display_line,
		part_no,
		[description],
		quantity)
	SELECT
		order_no,
		order_ext,
		line_no,
		display_line,
		part_no,
		[description],
		cr_ordered
	FROM
		dbo.ord_list  (NOLOCK)
	WHERE
		order_no = @order_no
		AND order_ext = @ext
		AND part_type IN ('P','C','N') -- v1.2 v1.3


	-- Check if email address exists
	IF EXISTS (SELECT 1 FROM dbo.cvo_raf_hdr (NOLOCK) WHERE spid = @spid AND ISNULL(contact_email,'') = '')
	BEGIN
		SELECT -2
		RETURN
	END

	SELECT 0
	RETURN
	
END
GO
GRANT EXECUTE ON  [dbo].[CVO_create_credit_return_raf_data_sp] TO [public]
GO
