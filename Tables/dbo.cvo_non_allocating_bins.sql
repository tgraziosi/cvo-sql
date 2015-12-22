CREATE TABLE [dbo].[cvo_non_allocating_bins]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		cvo_non_allocating_bins_d_trg		
Type:		Trigger
Description:	Update cvo_lot_bin_stock_exclusions
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	17/09/2011	Original Version

*/

CREATE TRIGGER [dbo].[cvo_non_allocating_bins_d_trg] ON [dbo].[cvo_non_allocating_bins]
FOR DELETE
AS
BEGIN
	DECLARE @bin_no		VARCHAR(12),
			@location	VARCHAR(10),
			@key		VARCHAR(30)
	
	-- Loop through deleted records
	SET @key = ''
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@key = location + '-' + bin_no,
			@location = location,
			@bin_no = bin_no
		FROM
			deleted
		WHERE
			location + '-' + bin_no > @key
		ORDER BY
			location + '-' + bin_no
			

		IF @@ROWCOUNT = 0
			BREAK

		-- Delete records from cvo_lot_bin_stock_exclusions which aren't also for inv_excluding bins
		DELETE FROM 
			cvo_lot_bin_stock_exclusions 
		WHERE 
			location = @location 
			AND bin_no = @bin_no
			AND inv_exclude = 0

		-- Update records which are also for non-inv_excluding bins
		UPDATE 
			cvo_lot_bin_stock_exclusions 
		SET
			non_allocating = 0
		WHERE 
			location = @location 
			AND bin_no = @bin_no
			AND inv_exclude = 1
	END
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		cvo_non_allocating_bins_i_trg		
Type:		Trigger
Description:	Update cvo_lot_bin_stock_exclusions
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	17/09/2011	Original Version

*/

CREATE TRIGGER [dbo].[cvo_non_allocating_bins_i_trg] ON [dbo].[cvo_non_allocating_bins]
FOR INSERT
AS
BEGIN
	DECLARE @bin_no		VARCHAR(12),
			@location	VARCHAR(10),
			@key		VARCHAR(30),
			@part_no	VARCHAR(30),
			@qty		DECIMAL(20,8)
	
	-- Loop through new records
	SET @key = ''
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@key = location + '-' + bin_no,
			@location = location,
			@bin_no = bin_no
		FROM
			inserted
		WHERE
			location + '-' + bin_no > @key
		ORDER BY
			location + '-' + bin_no
			

		IF @@ROWCOUNT = 0
			BREAK

		-- Loop through lot_bin_stock records for this location/bin
		SET @part_no = ''
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@part_no = part_no,
				@qty = qty
			FROM
				dbo.lot_bin_stock (NOLOCK)
			WHERE
				location = @location
				AND bin_no = @bin_no
				AND part_no > @part_no
			ORDER BY
				part_no

			IF @@ROWCOUNT = 0
				BREAK

			-- If entry already exists for this location/bin/part_no, just update non_allocating flag
			IF EXISTS (SELECT 1 FROM dbo.cvo_lot_bin_stock_exclusions (NOLOCK) WHERE location = @location AND bin_no = @bin_no AND part_no = @part_no)
			BEGIN

				UPDATE 
					dbo.cvo_lot_bin_stock_exclusions
				SET
					non_allocating = 1
				WHERE 
					location = @location 
					AND bin_no = @bin_no
					AND part_no = @part_no	
			END
			ELSE
			BEGIN
				INSERT dbo.cvo_lot_bin_stock_exclusions(
					location,
					bin_no,
					part_no,
					qty,
					non_allocating,
					inv_exclude)
				SELECT
					@location,
					@bin_no,
					@part_no,
					@qty,	
					1,
					0
			END

		END
	END
END

GO
CREATE NONCLUSTERED INDEX [cvo_non_allocating_bins_ind0] ON [dbo].[cvo_non_allocating_bins] ([location], [bin_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_non_allocating_bins] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_non_allocating_bins] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_non_allocating_bins] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_non_allocating_bins] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_non_allocating_bins] TO [public]
GO
