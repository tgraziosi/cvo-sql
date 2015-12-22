CREATE TABLE [dbo].[uom_id_code]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UOM] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UPC] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GTIN] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EAN_8] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EAN_13] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EAN_14] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[t700ins_uom_id_code_cust]
   ON  [dbo].[uom_id_code]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @i_part_no	VARCHAR(30),
			@i_uom		CHAR(2),
			@i_upc		VARCHAR(12),
			@i_gtin		VARCHAR(14),
			@i_ean_8	VARCHAR(8),
			@i_ean_13	VARCHAR(13),
			@i_ean_14	VARCHAR(14),
			@exists		VARCHAR(12)

    -- Insert statements for trigger here
	DECLARE c_uom_id_code CURSOR LOCAL FOR
	SELECT part_no, uom, upc, gtin, ean_8, ean_13, ean_14
	FROM inserted
	ORDER BY part_no, uom

	OPEN c_uom_id_code
	FETCH NEXT FROM c_uom_id_code INTO
	@i_part_no, @i_uom, @i_upc, @i_gtin, @i_ean_8, @i_ean_13, @i_ean_14

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @exists = ISNULL(upc, '') FROM uom_id_code WHERE upc = @i_upc and part_no <> @i_part_no
		
		IF @exists = @i_upc
		BEGIN
			rollback tran
			RAISERROR 84101 'There is a same UPC assigned to other item.'
			RETURN
		END 
		
		FETCH NEXT FROM c_uom_id_code INTO
		@i_part_no, @i_uom, @i_upc, @i_gtin, @i_ean_8, @i_ean_13, @i_ean_14
	END
	
	CLOSE c_uom_id_code
	DEALLOCATE c_uom_id_code

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[t700upd_uom_id_code_cust]
   ON  [dbo].[uom_id_code]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @i_part_no	VARCHAR(30),
			@i_uom		CHAR(2),
			@i_upc		VARCHAR(12),
			@i_gtin		VARCHAR(14),
			@i_ean_8	VARCHAR(8),
			@i_ean_13	VARCHAR(13),
			@i_ean_14	VARCHAR(14),
			@exists		VARCHAR(12)

    -- Insert statements for trigger here
	DECLARE c_uom_id_code CURSOR LOCAL FOR
	SELECT part_no, uom, upc, gtin, ean_8, ean_13, ean_14
	FROM inserted
	ORDER BY part_no, uom

	OPEN c_uom_id_code
	FETCH NEXT FROM c_uom_id_code INTO
	@i_part_no, @i_uom, @i_upc, @i_gtin, @i_ean_8, @i_ean_13, @i_ean_14

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @exists = ISNULL(upc, '%') FROM uom_id_code WHERE upc = @i_upc and part_no <> @i_part_no
		
		IF @exists = @i_upc
		BEGIN
			rollback tran
			RAISERROR 84101 'There is a same UPC assigned to other item.'
			RETURN
		END 
		
		FETCH NEXT FROM c_uom_id_code INTO
		@i_part_no, @i_uom, @i_upc, @i_gtin, @i_ean_8, @i_ean_13, @i_ean_14
	END
	
	CLOSE c_uom_id_code
	DEALLOCATE c_uom_id_code

END
GO
CREATE NONCLUSTERED INDEX [uom_id_code_indx4] ON [dbo].[uom_id_code] ([EAN_13]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [uom_id_code_indx5] ON [dbo].[uom_id_code] ([EAN_14]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [uom_id_code_indx3] ON [dbo].[uom_id_code] ([EAN_8]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [uom_id_code_indx2] ON [dbo].[uom_id_code] ([GTIN]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_uom_id_code] ON [dbo].[uom_id_code] ([part_no], [UOM]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [uom_id_code_indx1] ON [dbo].[uom_id_code] ([UPC]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[uom_id_code] TO [public]
GO
GRANT SELECT ON  [dbo].[uom_id_code] TO [public]
GO
GRANT INSERT ON  [dbo].[uom_id_code] TO [public]
GO
GRANT DELETE ON  [dbo].[uom_id_code] TO [public]
GO
GRANT UPDATE ON  [dbo].[uom_id_code] TO [public]
GO
