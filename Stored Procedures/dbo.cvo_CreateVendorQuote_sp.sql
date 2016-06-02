SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_CreateVendorQuote_sp.sql
Type:			Stored Procedure
Called From:	Enterprise
Description:	Creates a vendor quote
Returns:		0 = Successful, -1 = Not Successful
Developer:		Chris Tyler
Date:			24th March 2011

Revision History
v1.0	CT	24/03/11	Original version
v1.1	CB	11/02/2016 - Issue #1574 - Outsourcing - suppress return option
*/

CREATE PROCEDURE [dbo].[cvo_CreateVendorQuote_sp]	@item_no	varchar(30),
												@currency	varchar(10),
												@cost		decimal (20,8),
												@suppress	int = 0 -- v1.1
AS

DECLARE @valid_for		int,
		@vendor_no		varchar(12),
		@last_recv_date	datetime

SET @valid_for = 0
		
-- Get vendor for the part
SELECT 
	@vendor_no = vendor
FROM
	dbo.inv_master (NOLOCK)
WHERE
	part_no = @item_no

-- Check a vendor exists
IF ISNULL(@vendor_no,'') = ''
BEGIN
	-- v1.1 Start
	IF (@suppress = 0)
	BEGIN
		SELECT '-1'
	END
	-- v1.1 End
	RETURN -1
END

-- Get valid for value from config
SELECT 
	@valid_for = CAST(value_str AS INT)
FROM 
	dbo.config (NOLOCK) 
WHERE 
	flag = 'VEND_QUOTE_VALID_FOR'

-- Check valid for value is correct
IF @valid_for <= 0 
BEGIN
	-- v1.1 Start
	IF (@suppress = 0)
	BEGIN
		SELECT '-1'
	END
	-- v1.1 End
	RETURN -1
END

-- Add valid for days onto current date
SET @last_recv_date = DATEADD(d,@valid_for,getdate())

-- Remove time from date
SET @last_recv_date = CAST(FLOOR(CAST( @last_recv_date AS FLOAT))AS DATETIME)

-- Check if vendor quote already exists
IF EXISTS (SELECT 1 FROM dbo.vendor_sku (NOLOCK) WHERE vendor_no = @vendor_no AND sku_no = @item_no AND qty = 1 
												AND curr_key = @currency AND last_recv_date = @last_recv_date)
BEGIN
	-- v1.1 Start
	IF (@suppress = 0)
	BEGIN
		SELECT '-1'
	END
	-- v1.1 End
	RETURN -1
END

-- Insert record
INSERT INTO dbo.vendor_sku(
	sku_no,
	last_recv_date,
	vendor_no,
	vend_sku,
	last_price,
	qty,
	curr_key)
SELECT
	UPPER(@item_no),
	@last_recv_date,
	@vendor_no,
	'',
	@cost,
	1,
	@currency

IF (@@ROWCOUNT = 0) OR (@@ERROR <> 0)
BEGIN
	-- v1.1 Start
	IF (@suppress = 0)
	BEGIN
		SELECT '-1'
	END
	-- v1.1 End
	RETURN -1
END

-- v1.1 Start
IF (@suppress = 0)
BEGIN
	SELECT '0'
END
-- v1.1 End
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[cvo_CreateVendorQuote_sp] TO [public]
GO
