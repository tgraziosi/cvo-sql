SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			f_customer_pricing_exists		
Project ID:		Issue 717
Type:			Function
Description:	Checks if any customer pricing exists for a part
Returns:		0 = False
				1 = True
Developer:		Chris Tyler

Testing code:	SELECT retval from dbo.f_customer_pricing_exists('010125','0001','BC800ROS13515',2)

History
-------
v1.0	09/07/12	CT	Original version

*/

CREATE FUNCTION [dbo].[f_customer_pricing_exists] (@customer_key VARCHAR(10),@ship_to_no VARCHAR(10),@item VARCHAR(30), @qty DECIMAL (20,8)) 
RETURNS @rettab table (retval smallint)
AS
BEGIN
	DECLARE @retval		SMALLINT,
			@style		VARCHAR(40),
			@res_type	VARCHAR(10),
			@group		VARCHAR(10)

	-- Default to false
	SET @retval = 0

	-- PART LEVEL
	-- Check for customer/shipto
	IF ISNULL(@ship_to_no,'') <> ''
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE ilevel = 0 AND customer_key = @customer_key AND ship_to_no = @ship_to_no AND item = @item AND min_qty <= @qty AND ISNULL(style,'') = '' AND ISNULL(res_type,'') = '')
		BEGIN
			-- Return true
			INSERT @rettab VALUES(1)
			RETURN 
		END
	END

	-- Check for customer
	IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE ilevel = 0 AND customer_key = @customer_key AND ship_to_no = 'ALL' AND item = @item AND min_qty <= @qty AND ISNULL(style,'') = '' AND ISNULL(res_type,'') = '')
	BEGIN
		-- Return true
		INSERT @rettab VALUES(1)
		RETURN 
	END

	-- GROUP LEVEL
	-- Get style and res_type for part
	SELECT 
		@group = ISNULL(a.category,''),
		@res_type = ISNULL(a.type_code,''),
		@style = ISNULL(b.field_2,'')
	FROM
		dbo.inv_master a (NOLOCK)
	INNER JOIN
		dbo.inv_master_add b (NOLOCK)
	ON
		a.part_no = b.part_no
	WHERE
		a.part_no = @item

	-- Check for customer/shipto
	IF ISNULL(@ship_to_no,'') <> ''
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE ilevel = 1 AND customer_key = @customer_key AND ship_to_no = @ship_to_no AND item = @group AND min_qty <= @qty AND ISNULL(style,'') = '' AND ISNULL(res_type,'') = '')
		BEGIN
			-- Return true
			INSERT @rettab VALUES(1)
			RETURN 
		END
	END

	-- Check for customer
	IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE ilevel = 1 AND customer_key = @customer_key AND ship_to_no = 'ALL' AND item = @group AND min_qty <= @qty AND ISNULL(style,'') = '' AND ISNULL(res_type,'') = '')
	BEGIN
		-- Return true
		INSERT @rettab VALUES(1)
		RETURN 
	END

	-- Check for customer/shipto/style
	IF ISNULL(@ship_to_no,'') <> ''
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE ilevel = 1 AND customer_key = @customer_key AND ship_to_no = @ship_to_no AND item = @group AND min_qty <= @qty AND ISNULL(style,'') = @style AND ISNULL(res_type,'') = '')
		BEGIN
			-- Return true
			INSERT @rettab VALUES(1)
			RETURN 
		END
	END

	-- Check for customer/style
	IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE ilevel = 1 AND customer_key = @customer_key AND ship_to_no = 'ALL' AND item = @group AND min_qty <= @qty AND ISNULL(style,'') = @style AND ISNULL(res_type,'') = '')
	BEGIN
		-- Return true
		INSERT @rettab VALUES(1)
		RETURN 
	END

	-- Check for customer/shipto/res_type
	IF ISNULL(@ship_to_no,'') <> ''
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE ilevel = 1 AND customer_key = @customer_key AND ship_to_no = @ship_to_no AND item = @group AND min_qty <= @qty AND ISNULL(style,'') = '' AND ISNULL(res_type,'') = @res_type)
		BEGIN
			-- Return true
			INSERT @rettab VALUES(1)
			RETURN 
		END
	END

	-- Check for customer/res_type
	IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE ilevel = 1 AND customer_key = @customer_key AND ship_to_no = 'ALL' AND item = @group AND min_qty <= @qty AND ISNULL(style,'') = '' AND ISNULL(res_type,'') = @res_type)
	BEGIN
		-- Return true
		INSERT @rettab VALUES(1)
		RETURN 
	END

	-- Check for customer/shipto/style/res_type
	IF ISNULL(@ship_to_no,'') <> ''
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE ilevel = 1 AND customer_key = @customer_key AND ship_to_no = @ship_to_no AND item = @group AND min_qty <= @qty AND ISNULL(style,'') = @style AND ISNULL(res_type,'') = @res_type)
		BEGIN
			-- Return true
			INSERT @rettab VALUES(1)
			RETURN 
		END
	END

	-- Check for customer/style/res_type
	IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE ilevel = 1 AND customer_key = @customer_key AND ship_to_no = 'ALL' AND item = @group AND min_qty <= @qty AND ISNULL(style,'') = @style AND ISNULL(res_type,'') = @res_type)
	BEGIN
		-- Return true
		INSERT @rettab VALUES(1)
		RETURN 
	END

	-- Return false
	INSERT @rettab VALUES(0)
	RETURN 
END
GO
GRANT REFERENCES ON  [dbo].[f_customer_pricing_exists] TO [public]
GO
GRANT SELECT ON  [dbo].[f_customer_pricing_exists] TO [public]
GO
