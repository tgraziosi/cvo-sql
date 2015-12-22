CREATE TABLE [dbo].[CVO_autopack_carton]
(
[autopack_id] [int] NOT NULL IDENTITY(1, 1),
[carton_id] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[case_link] [int] NULL,
[case_link_deleted_line_no] [int] NULL,
[frame_link] [int] NULL,
[frame_link_deleted_line_no] [int] NULL,
[qty] [decimal] (20, 8) NOT NULL,
[picked] [decimal] (20, 8) NOT NULL,
[carton_no] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		cvo_autopack_carton_d_trg		
Type:		Trigger
Description:	Tidies carton information after records are deleted
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	25/07/2012	Original Version
v1.1	CT	05/10/2012	Change update to use index
*/

CREATE TRIGGER [dbo].[cvo_autopack_carton_d_trg] ON [dbo].[CVO_autopack_carton]
FOR DELETE
AS
BEGIN
	DECLARE	@autopack_id	int,
			@order_no		int,
			@order_ext		int,
			--@qty			decimal(20,8),	-- v1.1
			--@carton_id		int,		-- v1.1
			@line_no		int,
			@part_type		VARCHAR(10)

	SET @autopack_id = 0
		
	-- Get the order to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@autopack_id = autopack_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@line_no = line_no,
			--@qty = qty,	-- v1.1
			--@carton_id = carton_id, -- v1.1
			@part_type = part_type
		FROM 
			deleted 
		WHERE
			autopack_id > @autopack_id
		ORDER BY 
			autopack_id

		IF @@RowCount = 0
			Break
		
		-- If there are records linked to this one, break the relationship
		IF @part_type = 'CASE'
		BEGIN
			UPDATE 
				dbo.CVO_autopack_carton 
			SET
				case_link_deleted_line_no = @line_no
			WHERE 
				order_no = @order_no		-- v1.1
				AND order_ext = @order_ext	-- v1.1
				AND case_link = @autopack_id	
				
		END
		ELSE
		BEGIN
			UPDATE 
				dbo.CVO_autopack_carton 
			SET
				frame_link_deleted_line_no = @line_no
			WHERE 
				order_no = @order_no		-- v1.1
				AND order_ext = @order_ext	-- v1.1
				AND frame_link = @autopack_id
		END
	END			
END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		cvo_autopack_carton_u_trg		
Type:		Trigger
Description:	When lines are fully picked, packs them in a carton
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	25/07/2011	Original Version
*/

CREATE TRIGGER [dbo].[cvo_autopack_carton_u_trg] ON [dbo].[CVO_autopack_carton]
FOR UPDATE
AS
BEGIN
	DECLARE	@autopack_id	int,
			@order_no		int,
			@order_ext		int,
			@carton_id		int,
			@carton_no		int

	SET @autopack_id = 0
		
	-- Get the next line to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@autopack_id = i.autopack_id,
			@carton_id = i.carton_id,
			@carton_no = i.carton_no,
			@order_no = i.order_no,
			@order_ext = i.order_ext
		FROM 
			inserted i
		INNER JOIN
			deleted d
		ON
			i.autopack_id = d.autopack_id
		WHERE
			i.autopack_id > @autopack_id
			AND i.picked <> d.picked
			AND i.picked = i.qty
		ORDER BY 
			i.autopack_id

		IF @@ROWCOUNT = 0
			Break
		
		-- Pack into carton
		EXEC dbo.CVO_pack_autopack_carton_sp @autopack_id = @autopack_id, @carton_no = @carton_no OUTPUT

		-- If a carton_no was returned (it should have been), update any records for this carton and order with the carton_no
		IF @carton_no IS NOT NULL
		BEGIN
			UPDATE
				dbo.CVO_autopack_carton
			SET
				carton_no = @carton_no
			WHERE
				carton_id = @carton_id
				AND order_no = @order_no
				AND order_ext = @order_ext
				AND carton_no IS NULL
		END

		
	END			
END


GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_autopack_carton_pk] ON [dbo].[CVO_autopack_carton] ([autopack_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_autopack_carton_inx01] ON [dbo].[CVO_autopack_carton] ([carton_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_autopack_carton_inx03] ON [dbo].[CVO_autopack_carton] ([order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_autopack_carton_inx02] ON [dbo].[CVO_autopack_carton] ([order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_autopack_carton_inx04] ON [dbo].[CVO_autopack_carton] ([order_no], [order_ext], [picked]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_autopack_carton] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_autopack_carton] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_autopack_carton] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_autopack_carton] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_autopack_carton] TO [public]
GO
