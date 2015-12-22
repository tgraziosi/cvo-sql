SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 08/08/2013 - Issue #1526 If any of the lines are promo kits then expand them out
-- EXEC CVO_upload_credit_return_promo_kit_sp 56, '001'

CREATE PROC [dbo].[CVO_upload_credit_return_promo_kit_sp]	@spid		INT,
														@location	VARCHAR(10)
AS
BEGIN

	DECLARE @rec_id		INT,
			@part_no	VARCHAR(30),
			@quantity	DECIMAL(20,8)

	SET NOCOUNT ON


	-- If no promo kits then exit
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_upload_credit_return_det a (NOLOCK) INNER JOIN dbo.inv_master_add b (NOLOCK)
						ON a.part_no = b.part_no WHERE a.spid = @spid AND ISNULL(b.field_30, 'N') = 'Y')
	BEGIN
		RETURN
	END
		
	-- Create temp table
	CREATE TABLE #temp_det(
			rec_id			INT IDENTITY(1,1) NOT NULL,
			spid			INT NOT NULL,
			part_no			VARCHAR(30) NOT NULL,
			quantity		DECIMAL(20,8) NOT NULL)

	-- Loop through table
	SET @rec_id = 0
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

		-- Check if part is a promo kit
		IF EXISTS (SELECT 1 FROM dbo.inv_master_add (NOLOCK) WHERE part_no = @part_no AND ISNULL(field_30, 'N') = 'Y')
		BEGIN
			-- Kit - add kit items to temp table
			INSERT INTO #temp_det(
				spid,
				part_no,
				quantity)
			SELECT
				@spid,
				a.part_no,
				@quantity * a.qty
			FROM
				dbo.what_part a (NOLOCK)
			INNER JOIN 
				dbo.inv_list b (NOLOCK) 
			ON 
				a.part_no = b.part_no
			WHERE 
				a.asm_no = @part_no 
				AND b.location = @location
			ORDER BY
				a.seq_no
		END
		ELSE
		BEGIN
			-- Not kit - add line to temp table
			INSERT INTO #temp_det(
				spid,
				part_no,
				quantity)
			SELECT
				spid,
				part_no,
				quantity
			FROM
				dbo.cvo_upload_credit_return_det (NOLOCK)
			WHERE
				spid = @spid
				AND rec_id = @rec_id

		END
	END

	-- Clear out existing data from table
	DELETE FROM dbo.cvo_upload_credit_return_det WHERE spid = @spid
	
	-- Load data from temp table
	INSERT INTO dbo.cvo_upload_credit_return_det(
		spid,
		part_no,
		quantity)
	SELECT
		spid,
		part_no,
		quantity
	FROM
		#temp_det	
	ORDER BY	 
		rec_id

	DROP TABLE #temp_det

END
GO
GRANT EXECUTE ON  [dbo].[CVO_upload_credit_return_promo_kit_sp] TO [public]
GO
