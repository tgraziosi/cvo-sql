CREATE TABLE [dbo].[cvo_soft_alloc_hdr]
(
[soft_alloc_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bo_hold] [int] NOT NULL,
[status] [smallint] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--v1.0	CB	16/10/2011	Original Version

CREATE TRIGGER [dbo].[cvo_soft_alloc_hdr_del_trg] ON [dbo].[cvo_soft_alloc_hdr]
FOR DELETE
AS
BEGIN

	DELETE	a
	FROM	dbo.cvo_soft_alloc_ctl a
	JOIN	deleted b
	ON		a.soft_alloc_no = b.soft_alloc_no

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0	CB 16/10/2011	Original Version
-- v1.1 CB 05/07/2013	Issue #1325 - Keep soft alloc number	
-- v1.2 CB 16/06/2014 - Add ROWLOCK
-- v1.3 CB 19/06/2014 - Add NOLOCK

CREATE TRIGGER [dbo].[cvo_soft_alloc_hdr_trg] ON [dbo].[cvo_soft_alloc_hdr]
FOR INSERT, UPDATE
AS
BEGIN

	-- New record
	IF UPDATE (soft_alloc_no)
	BEGIN
		INSERT	dbo.cvo_soft_alloc_ctl WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, date_entered)
		SELECT	soft_alloc_no, order_no, order_ext, GETDATE()
		FROM	inserted
		RETURN
	END

	-- New record
	IF UPDATE (order_no)
	BEGIN
		UPDATE	a
		SET		order_no = b.order_no,
				order_ext = b.order_ext
		FROM	dbo.cvo_soft_alloc_ctl a WITH (ROWLOCK)
		JOIN	inserted b
		ON		a.soft_alloc_no = b.soft_alloc_no

		-- v1.1 Start
		INSERT	cvo_soft_alloc_no_assign WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext)
		SELECT	a.soft_alloc_no, 
				a.order_no, 
				a.order_ext
		FROM	inserted a
		LEFT JOIN cvo_soft_alloc_no_assign b (NOLOCK) -- v1.3
		ON		a.soft_alloc_no = b.soft_alloc_no
		AND		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		WHERE	b.soft_alloc_no IS NULL
		-- v1.1 End

		RETURN
	END

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[epicr_debug_cvo_soft_alloc_hdr_trg]
ON [dbo].[cvo_soft_alloc_hdr]
FOR UPDATE
AS
BEGIN

	INSERT	dbo.epicor_debug_cvo_soft_alloc_hdr
	SELECT	a.soft_alloc_no,
			a.order_no,
			a.order_ext,
			GETDATE(),
			a.status,
			b.status
	FROM	inserted a
	JOIN	deleted b
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	a.status <> b.status

END
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_hdr_ind1] ON [dbo].[cvo_soft_alloc_hdr] ([order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_hdr_ind3] ON [dbo].[cvo_soft_alloc_hdr] ([order_no], [order_ext], [status], [bo_hold]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_hdr_ind0] ON [dbo].[cvo_soft_alloc_hdr] ([soft_alloc_no], [order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_hdr_ind2] ON [dbo].[cvo_soft_alloc_hdr] ([status]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_soft_alloc_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_soft_alloc_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_soft_alloc_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_soft_alloc_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_soft_alloc_hdr] TO [public]
GO
