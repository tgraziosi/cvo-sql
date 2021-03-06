CREATE TABLE [dbo].[CVO_ord_list_kit]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[replaced] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_ord_l__repla__3338F640] DEFAULT ('N'),
[new1] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_ord_li__new1__342D1A79] DEFAULT ('N'),
[part_no_original] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger CVO_ord_list_kit_trg    Script Date: 12/01/2010  ***** 
Object:      Trigger  CVO_ord_list_kit_trg  
Source file: CVO_ord_list_kit_trg.sql
Author:		 Craig Boston
Created:	 12/02/2010
Function:    
Modified:    
Calls:    
Called by:   
Copyright:   Epicor Software 2010.  All rights reserved.  
select * from cvo_ord_list_kit where order_no = 1282
v1.1 CB 02/15/2011	Only run code when the order has a status of N
v1.2 CB 14/12/2012  Issue #1026 - Need to run when the status is also 'A' or 'C'
v1.3 CB 09/01/2013  Issue #1067 - Add in status of Q
v1.4 CB 24/08/2016 - CVO-CF-49 - Dynamic Custom Frames
v1.5 CB 15/09/2016 - Force sort order as row_id in CVO_ord_list_kit
*/

CREATE TRIGGER [dbo].[CVO_ord_list_kit_trg] 
ON [dbo].[CVO_ord_list_kit]
FOR INSERT, UPDATE
AS
BEGIN
	-- Declarations
	DECLARE	@location		varchar(10),
			@part_no		varchar(30),
			@qty			decimal(20,8),
			@order_no		int,
			@order_ext		int,
			@line_no		int,
			@last_part_no	varchar(30),
			@original_part	varchar(30),
			@row_id			int,
			@part_no_original varchar(30),
			@last_row_id	int,
			@part_type		varchar(5), -- v1.4
			@last_line		int -- v1.4

	-- v1.5 Start
	CREATE TABLE #kit_table (
		row_id				int IDENTITY(1,1),
		location			varchar(10),
		part_no				varchar(30),
		order_no			int,
		order_ext			int,
		line_no				int,
		part_no_original	varchar(30),
		part_type			varchar(10))

	INSERT	#kit_table (location, part_no, order_no, order_ext, line_no, part_no_original, part_type)
	SELECT	a.location,
			a.part_no,
			a.order_no,
			a.order_ext,
			a.line_no,		
			a.part_no_original,
			b.part_type -- v1.4
	FROM	inserted a
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.replaced = 'S'
	AND		b.status IN ('N','A','C','Q') -- v1.2 v1.3	
	ORDER BY order_no, order_ext, line_no
	-- v1.5 End

	-- Processing the components of a custom frame when they have been substituted
	-- When the lines are substituted then create MGTB2B moves
	-- Get the information from the record
--	SET @last_part_no = ''
	SET @last_row_id = 0
	SET @last_line = 0

	-- v1.5 Start
	SELECT	TOP 1 @location = location,
			@part_no = part_no,
			@order_no = order_no,
			@order_ext = order_ext,
			@line_no = line_no,
			@row_id = row_id,
			@part_no_original = part_no_original,
			@part_type = part_type -- v1.4
	FROM	#kit_table
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
/*
	SELECT	TOP 1 @location = a.location,
			@part_no = a.part_no,
			@order_no = a.order_no,
			@order_ext = a.order_ext,
			@line_no = a.line_no,
			@row_id = a.row_id,
			@part_no_original = a.part_no_original,
			@part_type = b.part_type -- v1.4
	FROM	inserted a
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.replaced = 'S'
	AND		a.row_id > @last_row_id
--	AND		a.part_no > @last_part_no
-- v1.2	AND		b.status = 'N'
	AND		b.status IN ('N','A','C','Q') -- v1.2 v1.3
	ORDER BY a.row_id
*/
	-- v1.5 End

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- v1.4 Start
		IF (@part_type <> 'C')
		BEGIN

			-- Get the qty from the ord_list record for the frame
			SELECT	@qty = ordered
			FROM	ord_list (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
		
			-- Get the original part
			SELECT	@original_part = part_no
			FROM	deleted
			WHERE	row_id = @row_id

			-- Call custom routine to generate MGTB2B for sustituted component items
			EXEC dbo.CVO_Create_Substitution_MGMB2B_Moves_sp @order_no, @order_ext, @line_no, @location, @part_no, @original_part, @part_no_original, @qty

		END
		ELSE
		BEGIN

			IF (@line_no > @last_line)
			BEGIN
				EXEC dbo.cvo_process_custom_kit_sp @order_no, @order_ext, @line_no, 0
			END
			SET @last_line = @line_no

		END	
		-- v1.4 End	


--		SET @last_part_no = @part_no
		SET @last_row_id = @row_id

		-- v1.5 Start
		SELECT	TOP 1 @location = location,
				@part_no = part_no,
				@order_no = order_no,
				@order_ext = order_ext,
				@line_no = line_no,
				@row_id = row_id,
				@part_no_original = part_no_original,
				@part_type = part_type -- v1.4
		FROM	#kit_table
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
/*

		SELECT	TOP 1 @location = a.location,
				@part_no = a.part_no,
				@order_no = a.order_no,
				@order_ext = a.order_ext,
				@line_no = a.line_no,
				@row_id = a.row_id,
				@part_no_original = a.part_no_original,
				@part_type = b.part_type -- v1.4
		FROM	inserted a
		JOIN	ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.replaced = 'S'
--		AND		a.part_no > @last_part_no
		AND		a.row_id > @last_row_id
-- v1.2	AND		b.status = 'N'
		AND		b.status IN ('N','A','C','Q') -- v1.2 v1.3
		ORDER BY a.row_id
*/
		-- v1.5 End
	END

	DROP TABLE #kit_table -- v1.5

END
GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_ord_list_kit] ON [dbo].[CVO_ord_list_kit] ([order_no], [order_ext], [line_no], [location], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_ord_list_kit_ind0] ON [dbo].[CVO_ord_list_kit] ([order_no], [order_ext], [line_no], [replaced]) ON [PRIMARY]
GO

GRANT REFERENCES ON  [dbo].[CVO_ord_list_kit] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_ord_list_kit] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_ord_list_kit] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_ord_list_kit] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_ord_list_kit] TO [public]
GO
