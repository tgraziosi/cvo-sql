CREATE TABLE [dbo].[cvo_st_consolidate_release]
(
[consolidation_no] [int] NULL,
[released] [int] NULL,
[release_date] [datetime] NULL,
[release_user] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[cvo_st_consolidate_release_upd_trg] 
ON [dbo].[cvo_st_consolidate_release]
FOR UPDATE
AS
BEGIN
	-- DECLARATIONS
	DECLARE	@cons_no		int,
			@last_cons_no	int,
			@order_no		int,
			@order_ext		int,
			@email_address	varchar(255),
			@cust_code		varchar(10),
			@ship_to		varchar(10)
		
	-- PROCESSING
	SET @last_cons_no = 0

	SELECT	TOP 1 @cons_no = a.consolidation_no
	FROM	inserted a
	JOIN	deleted b
	ON		a.consolidation_no = b.consolidation_no
	WHERE	a.consolidation_no > @last_cons_no
	AND		a.released = 1
	AND		b.released = 0
	ORDER BY a.consolidation_no ASC
	
	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		SELECT	TOP 1 @order_no = a.order_no,
				@order_ext = a.ext,
				@email_address = a.email_address,
				@cust_code = c.cust_code,
				@ship_to = c.ship_to	
		FROM	cvo_orders_all a (NOLOCK)
		JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.ext = b.order_ext
		JOIN	orders_all c (NOLOCK)
		ON		a.order_no = c.order_no
		AND		a.ext = c.ext
		WHERE	b.consolidation_no = @cons_no

		EXEC dbo.cvo_email_order_confirmation_sp @order_no, @order_ext, @cust_code, @ship_to, @email_address, @cons_no

		SET @last_cons_no = @cons_no

		SELECT	TOP 1 @cons_no = a.consolidation_no
		FROM	inserted a
		JOIN	deleted b
		ON		a.consolidation_no = b.consolidation_no
		WHERE	a.consolidation_no > @last_cons_no
		AND		a.released = 1
		AND		b.released = 0
		ORDER BY a.consolidation_no ASC

	END

RETURN

END
GO
CREATE NONCLUSTERED INDEX [cvo_st_consolidate_release_ind0] ON [dbo].[cvo_st_consolidate_release] ([consolidation_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_st_consolidate_release] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_st_consolidate_release] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_st_consolidate_release] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_st_consolidate_release] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_st_consolidate_release] TO [public]
GO
