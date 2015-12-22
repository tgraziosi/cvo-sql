SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1 CT 19/11/2013 - Issue #1420 - Don't return kit items which aren't valid at both the from and to locations

CREATE PROC [dbo].[CVO_get_promo_kit_parts_sp]	@asm_no VARCHAR(30), 
											@qty DECIMAL(20,8),
											@location VARCHAR(10),
											@to_loc VARCHAR(10) -- v1.1
AS
BEGIN
	DECLARE @part_no	VARCHAR(30),
			@rec_id		INT,
			@reqd_qty	DECIMAL(20,8),
			@avail_qty	DECIMAL(20,8)

	-- Create temp table
	CREATE TABLE #kit(
		rec_id		INT IDENTITY (1,1),
		part_no		VARCHAR(30),
		qty			DECIMAL(20,8),
		avail_qty	DECIMAL(20,8),
		available	SMALLINT)

	-- Load in kit parts
	INSERT INTO #kit(
		part_no,
		qty,
		available,
		avail_qty)
	SELECT
		part_no, 
		qty * @qty,
		0,
		0
	FROM 
		dbo.what_part (NOLOCK)
	WHERE 
		active = 'A' 
		AND asm_no = @asm_no 
		-- START v1.1
		AND part_no IN (SELECT part_no FROM dbo.inv_list (NOLOCK) WHERE location = @location)
		AND part_no IN (SELECT part_no FROM dbo.inv_list (NOLOCK) WHERE location = @to_loc)
		-- END v1.1
	ORDER BY part_no

	-- Loop through and check stock
	SET @rec_id = 0
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1
			@rec_id = rec_id,
			@part_no = part_no,
			@reqd_qty = qty
		FROM
			#kit
		WHERE
			rec_id > @rec_id
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Get available qty
		EXEC @avail_qty = CVO_CheckAvailabilityInStock_sp   @part_no, @location, 0

		IF ISNULL(@avail_qty,0) <> 0	
		BEGIN
			-- If not all stock is available, update reqd_qty to what is available
			IF @avail_qty < @reqd_qty
			BEGIN
				UPDATE 
					#kit 
				SET 
					available = 2,
					qty = @avail_qty,
					avail_qty = @avail_qty
				WHERE
					rec_id = @rec_id
			END
			ELSE
			BEGIN
				-- Show part as available
				UPDATE 
					#kit 
				SET 
					available = 1,
					avail_qty = @avail_qty
				WHERE
					rec_id = @rec_id
			END
		END
				
	END

	-- Return available kit parts
	SELECT
		part_no,
		CASE available WHEN 0 THEN 0 ELSE qty END qty,
		available,
		avail_qty
	FROM
		#kit
	ORDER BY 
		part_no

END
GO
GRANT EXECUTE ON  [dbo].[CVO_get_promo_kit_parts_sp] TO [public]
GO
