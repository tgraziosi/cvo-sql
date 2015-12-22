CREATE TABLE [dbo].[lot_bin_stock]
(
[timestamp] [timestamp] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_tran] [datetime] NOT NULL,
[date_expires] [datetime] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[cost] [decimal] (20, 8) NOT NULL,
[qty_physical] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 22/04/2015 - Performance Changes  
  
CREATE TRIGGER [dbo].[lbstockinsupd700t] ON [dbo].[lot_bin_stock]   
FOR INSERT,UPDATE   
AS  
BEGIN  
	declare @cnt int  
	declare @cnt1 int          -- mls 6/23/00 SCR 23164  
	declare @lotbin varchar(7) -- SCR 20940  
	declare @part_no varchar(30), @qty decimal(20,8), @serial_flag int  
	declare @last_part varchar(30)  
  
	IF NOT EXISTS (SELECT 1 FROM inserted) RETURN  

	-- v1.0 Start
	DECLARE	@row_id			int,
			@last_row_id	int

	CREATE TABLE #c_lbs (
		row_id			int IDENTITY(1,1),
		part_no			varchar(30) NULL,
		qty				decimal(20,8) NULL,
		serial_flag		int NULL)
  
	SELECT @lotbin = ISNULL((SELECT value_str FROM config (NOLOCK) WHERE flag = 'INV_LOT_BIN'),'YES')  
	SELECT @last_part = ''  

	INSERT	#c_lbs (part_no, qty, serial_flag)
    -- v1.0 DECLARE c_lbs CURSOR FOR  
	SELECT	i.part_no, 
			i.qty, 
			ISNULL(m.serial_flag,0)  
	FROM	inserted i  
	LEFT OUTER JOIN inv_master m (NOLOCK) 
	ON	i.part_no = m.part_no  
	ORDER BY i.part_no  
  
	-- v1.0 OPEN c_lbs  

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@part_no = part_no,
			@qty = qty,
			@serial_flag = serial_flag
	FROM	#c_lbs
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
  
	-- Get first row  
	-- v1.0 FETCH c_lbs INTO @part_no, @qty, @serial_flag  
	-- v1.0 WHILE @@fetch_status = 0  
	WHILE (@@ROWCOUNT <> 0)  
	BEGIN  
       
		IF @lotbin = 'YES' AND @serial_flag = 1 AND @qty > 1  
		BEGIN  
			-- v1.0 CLOSE c_lbs  
			-- v1.0 DEALLOCATE c_lbs  
			ROLLBACK TRAN  
			EXEC adm_raiserror 83901,'Qty can not exceed 1 for serial tracked items.'  
			RETURN  
		END  
  
		IF @serial_flag = 1 AND @part_no != @last_part  
		BEGIN  
			SELECT	@cnt = ISNULL((SELECT SUM(i.qty) FROM inserted i WHERE i.part_no = @part_no),0)  
			SELECT  @cnt1 = ISNULL((SELECT SUM(s.qty) FROM lot_bin_stock s (NOLOCK), inserted i  
								WHERE s.part_no = i.part_no AND s.lot_ser = i.lot_ser AND i.part_no = @part_no),0)  
      
		    IF @cnt != @cnt1   
			BEGIN        -- mls 6/23/00 SCR 23164 end  
				-- v1.0 CLOSE c_lbs  
				-- v1.0 DEALLOCATE c_lbs  
				ROLLBACK TRAN  
				EXEC adm_raiserror 83902 ,'This Lot/Serial Number already exists.'  
				RETURN  
			END  
		END  
  
		SELECT @last_part = @part_no  

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@part_no = part_no,
				@qty = qty,
				@serial_flag = serial_flag
		FROM	#c_lbs
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC    

		-- v1.0 FETCH c_lbs INTO @part_no, @qty, @serial_flag  
	END --while part  
  
	-- v1.0 CLOSE c_lbs  
	-- v1.0 DEALLOCATE c_lbs  
 
END  
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		lot_bin_stock_d_trg		
Type:		Trigger
Description:	Update cvo_lot_bin_stock_exclusions
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	17/09/2011	Original Version

*/

CREATE TRIGGER [dbo].[lot_bin_stock_d_trg] ON [dbo].[lot_bin_stock]
FOR DELETE
AS
BEGIN
	DECLARE @bin_no		VARCHAR(12),
			@location	VARCHAR(10),
			@part_no	VARCHAR(30),
			@key		VARCHAR(60)
	
	-- Loop through deleted records
	SET @key = ''
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@key = location + '-' + bin_no + '-' + part_no,
			@location = location,
			@bin_no = bin_no,
			@part_no = part_no
		FROM
			deleted
		WHERE
			location + '-' + bin_no + '-' + part_no > @key
		ORDER BY
			location + '-' + bin_no + '-' + part_no
			

		IF @@ROWCOUNT = 0
			BREAK

		-- Delete records from cvo_lot_bin_stock_exclusions
		DELETE FROM 
			cvo_lot_bin_stock_exclusions 
		WHERE 
			location = @location 
			AND bin_no = @bin_no
			AND part_no = @part_no
	END
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		lot_bin_stock_iu_trg		
Type:		Trigger
Description:	Update cvo_lot_bin_stock_exclusions
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	17/09/2011	Original Version

*/

CREATE TRIGGER [dbo].[lot_bin_stock_iu_trg] ON [dbo].[lot_bin_stock]
FOR INSERT,UPDATE
AS
BEGIN
	DECLARE @bin_no			VARCHAR(12),
			@location		VARCHAR(10),
			@key			VARCHAR(60),
			@part_no		VARCHAR(30),
			@qty			DECIMAL(20,8),
			@non_allocating	SMALLINT,
			@inv_exclude	SMALLINT
	
	-- Loop through new records
	SET @key = ''
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@key = location + '-' + bin_no + '-' + part_no,
			@location = location,
			@bin_no = bin_no,
			@part_no = part_no,
			@qty = qty
		FROM
			inserted
		WHERE
			location + '-' + bin_no + '-' + part_no > @key
		ORDER BY
			location + '-' + bin_no + '-' + part_no
			

		IF @@ROWCOUNT = 0
			BREAK


		-- Check if bin is a used in stock exclusions
		IF EXISTS (SELECT 1 FROM cvo_non_allocating_bins WHERE location = @location AND bin_no = @bin_no)
		BEGIN
			SET @non_allocating = 1
		END
		ELSE
		BEGIN
			SET @non_allocating = 0
		END

		IF EXISTS (SELECT 1 FROM cvo_inv_excluded_bins WHERE location = @location AND bin_no = @bin_no)
		BEGIN
			SET @inv_exclude = 1
		END
		ELSE
		BEGIN
			SET @inv_exclude = 0
		END

		-- If this is a bin to be excluded
		IF (@non_allocating = 1) OR (@inv_exclude = 1)
		BEGIN

			-- If entry already exists for this location/bin/part_no, just update it
			IF EXISTS (SELECT 1 FROM dbo.cvo_lot_bin_stock_exclusions (NOLOCK) WHERE location = @location AND bin_no = @bin_no AND part_no = @part_no)
			BEGIN

				UPDATE 
					dbo.cvo_lot_bin_stock_exclusions
				SET
					qty = @qty		
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
					@non_allocating,
					@inv_exclude
			END

		END
	END
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t500dellbstock] ON [dbo].[lot_bin_stock]   FOR DELETE  AS 
BEGIN
if exists (select * from deleted where qty <> 0) BEGIN
	rollback tran
	exec adm_raiserror 73999 ,'Stock Deletion That Is NON-ZERO Is Not Allowed!'
	return
	END
END

GO
CREATE NONCLUSTERED INDEX [lot_bin_stock_ind_loc_bin] ON [dbo].[lot_bin_stock] ([location], [bin_no]) INCLUDE ([qty], [part_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [lbstk1] ON [dbo].[lot_bin_stock] ([location], [part_no], [bin_no], [lot_ser]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [lbstk2] ON [dbo].[lot_bin_stock] ([part_no], [lot_ser]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[lot_bin_stock] TO [public]
GO
GRANT SELECT ON  [dbo].[lot_bin_stock] TO [public]
GO
GRANT INSERT ON  [dbo].[lot_bin_stock] TO [public]
GO
GRANT DELETE ON  [dbo].[lot_bin_stock] TO [public]
GO
GRANT UPDATE ON  [dbo].[lot_bin_stock] TO [public]
GO
