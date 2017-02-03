CREATE TABLE [dbo].[cvo_buying_groups_hist]
(
[parent] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[relation_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_date_int] [int] NULL,
[start_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_date_int] [int] NULL,
[end_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buying_group_no] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[modified_on_int] [int] NOT NULL,
[modified_on] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[cvo_bg_hist_upd_trg] ON [dbo].[cvo_buying_groups_hist]
FOR UPDATE
AS
BEGIN
	-- DECLARATIONS
	DECLARE @row_id			int,
			@last_row_id	int,
			@parent			varchar(10),
			@child			varchar(10)

	-- WORKING TABLE
	CREATE TABLE #clean_bg (
		row_id		int IDENTITY(1,1),
		parent		varchar(10),
		child		varchar(10))

	-- PROCESS
	INSERT	#clean_bg (parent, child)
	SELECT	a.parent, a.child
	FROM	inserted a
	JOIN	deleted b
	ON		a.parent = b.parent
	AND		a.child = b.child
	WHERE	a.end_date IS NOT NULL
	AND		b.end_date IS NULL

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@parent = parent,
			@child = child
	FROM	#clean_bg
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		DELETE	arnarel
		WHERE	parent = @parent
		AND		child = @child

		DELETE	artierrl
		WHERE	parent = @parent
		AND		rel_cust = @child
		AND		tier_level = 2
	
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@parent = parent,
				@child = child
		FROM	#clean_bg
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC		
	END					


END
GO
CREATE NONCLUSTERED INDEX [cvo_buying_groups_hist_ind1] ON [dbo].[cvo_buying_groups_hist] ([child], [start_date], [end_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_buying_groups_hist_ind0] ON [dbo].[cvo_buying_groups_hist] ([parent], [start_date], [end_date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_buying_groups_hist] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_buying_groups_hist] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_buying_groups_hist] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_buying_groups_hist] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_buying_groups_hist] TO [public]
GO
