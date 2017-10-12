CREATE TABLE [dbo].[artrxage]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[ref_id] [int] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cust_po_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[sub_apply_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_apply_type] [smallint] NOT NULL,
[date_doc] [int] NOT NULL,
[date_due] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_aging] [int] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [float] NOT NULL,
[paid_flag] [smallint] NOT NULL,
[group_id] [int] NOT NULL,
[amt_fin_chg] [float] NOT NULL,
[amt_late_chg] [float] NOT NULL,
[amt_paid] [float] NOT NULL,
[payer_cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_oper] [float] NOT NULL,
[rate_home] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[true_amount] [float] NOT NULL,
[date_paid] [int] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[artrxage_cvo_tr] ON [dbo].[artrxage]
FOR INSERT
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@row_id			int,
			@customer_code	varchar(16),
			@doc_ctrl_num	varchar(16),
			@order_ctrl_num	varchar(16),
			@date_doc		int,
			@parent			varchar(10)

	-- WORKING TABLE
	CREATE TABLE #cvo_artrxage_insert (
		row_id			int IDENTITY(1,1),
		customer_code	varchar(10),
		doc_ctrl_num	varchar(16),
		apply_to_num	varchar(16),
		order_ctrl_num	varchar(16),
		date_doc		int,
		parent			varchar(10),
		trx_type		int,
		is_done			int)

	-- PROCESSING
	INSERT	#cvo_artrxage_insert (customer_code, doc_ctrl_num, apply_to_num, order_ctrl_num, date_doc, parent, trx_type, is_done)
	SELECT	DISTINCT customer_code, doc_ctrl_num, apply_to_num, order_ctrl_num, date_doc, '', trx_type, 0
	FROM	inserted

	-- If the transaction originated from sales order or credit return then set the buying group as per the cvo_orders_all table.
	UPDATE	a
	SET		parent = b.buying_group,
			is_done = 1
	FROM	#cvo_artrxage_insert a
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_ctrl_num = CAST(b.order_no as varchar(20)) + '-' + CAST(b.ext as varchar(10))
	-- WHERE	ISNULL(b.buying_group,'NULL') <> 'NULL'
	WHERE	ISNULL(b.buying_group,'') <> ''

	-- For finance or late charge use the doc date from the invoice the charge is applied to
	UPDATE	a
	SET		date_doc = c.date_doc
	FROM	#cvo_artrxage_insert a
	JOIN	artrxage b(NOLOCK)
	ON		a.customer_code = b.customer_code
	AND		a.doc_ctrl_num = b.doc_ctrl_num
	JOIN	artrxage c
	ON		a.customer_code = b.customer_code	
	AND		b.apply_to_num = c.doc_ctrl_num
	WHERE	(LEFT(a.doc_ctrl_num,3) = 'FIN' OR LEFT(a.doc_ctrl_num,4) = 'LATE')

	-- For a chargeback use the date doc from the invoice the charge is applied to
	UPDATE	c
	SET		date_doc = a.date_doc
	FROM	artrxage a (NOLOCK)
	JOIN	artrxage b (NOLOCK)
	ON		a.doc_ctrl_num = b.apply_to_num
	AND		a.customer_code = b.customer_code	
	JOIN	#cvo_artrxage_insert c
	ON		b.customer_code = c.customer_code	
	AND		b.doc_ctrl_num = c.doc_ctrl_num
	WHERE	a.trx_type = 2031
	AND		b.trx_type = 2111
	AND		LEFT(b.trx_ctrl_num,2) = 'CB'

	-- Process the transactions setting the parent
	SET @row_id = 0

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @row_id = row_id,
				@customer_code = customer_code,
				@doc_ctrl_num = doc_ctrl_num,
				@order_ctrl_num = order_ctrl_num,
				@date_doc = date_doc
		FROM	#cvo_artrxage_insert
		WHERE	row_id > @row_id
		AND		is_done = 0
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		-- Get parent where customer has left the buying group
		SET @parent = NULL

		SELECT	@parent = parent
		FROM	cvo_buying_groups_hist (NOLOCK)
		WHERE	child = @customer_code
		AND		@date_doc >= start_date_int
		AND		@date_doc <= end_date_int

		UPDATE	#cvo_artrxage_insert
		SET		parent = @parent,
				is_done = 1
		WHERE	customer_code = @customer_code
		AND		date_doc = @date_doc
		AND		is_done = 0
		AND		@parent IS NOT NULL

		-- Get parent where customer currently with a buying group
		SET @parent = NULL

		SELECT	@parent = parent
		FROM	cvo_buying_groups_hist (NOLOCK)
		WHERE	child = @customer_code
		AND		@date_doc >= start_date_int
		AND		@date_doc <= ISNULL(end_date_int,@date_doc)

		UPDATE	#cvo_artrxage_insert
		SET		parent = @parent,
				is_done = 1
		WHERE	customer_code = @customer_code
		AND		date_doc = @date_doc
		AND		is_done = 0
		AND		@parent IS NOT NULL

		-- Get parent where customer is part of a national account
		UPDATE	a
		SET		parent = b.parent,
				is_done = 1
		FROM	#cvo_artrxage_insert a
		JOIN	artierrl b (NOLOCK)
		ON		a.customer_code = b.rel_cust
		WHERE	a.customer_code = @customer_code
		AND		b.tier_level >= 2			
							
	END

	-- Update the remaining records with no parent
	UPDATE	#cvo_artrxage_insert
	SET		parent = customer_code,
			is_done = 1
	WHERE	is_done = 0

	-- Populate the final table
	INSERT	dbo.cvo_artrxage (doc_ctrl_num,	order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
	SELECT	a.doc_ctrl_num, a.apply_to_num, a.customer_code, a.date_doc, CONVERT(varchar(10),DATEADD(day, a.date_doc - 693596, '01/01/1900'),121), a.parent
	FROM	#cvo_artrxage_insert a
	LEFT JOIN cvo_artrxage b (NOLOCK)
	ON		a.doc_ctrl_num = b.doc_ctrl_num
	AND		a.apply_to_num = b.order_ctrl_num
	AND		a.customer_code = b.customer_code
	WHERE	b.doc_ctrl_num IS NULL
	AND		b.order_ctrl_num IS NULL
	AND		b.customer_code IS NULL

	DROP TABLE #cvo_artrxage_insert

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--v1.0 TM	02/22/2012	Set the Due Date of the Credits properly based on CVO criteria
  
CREATE TRIGGER [dbo].[CVO_arageins_tr] ON [dbo].[artrxage] AFTER INSERT
AS   
BEGIN
  
DECLARE	@trx_ctrl_num		varchar(16),
		@doc_ctrl_num		varchar(16),
		@date_due			int,
		@trx_type			int

DECLARE ins_arinp CURSOR LOCAL FOR SELECT i.trx_ctrl_num, i.trx_type, i.doc_ctrl_num FROM inserted i

OPEN ins_arinp
FETCH NEXT FROM ins_arinp INTO @trx_ctrl_num, @trx_type, @doc_ctrl_num

WHILE @@FETCH_STATUS=0
 BEGIN

 IF @trx_type = 2161 AND @doc_ctrl_num like 'CRM%' 		-- invoice or credit entered direct into AR
    BEGIN
		SELECT @date_due = date_due FROM artrx_all WHERE doc_ctrl_num = @doc_ctrl_num AND trx_type = 2032
		UPDATE	artrxage 
		   SET 	date_due = @date_due
		 WHERE	trx_ctrl_num = @trx_ctrl_num
    END

   FETCH NEXT FROM ins_arinp INTO  @trx_ctrl_num, @trx_type, @doc_ctrl_num
 END

END

close ins_arinp
deallocate ins_arinp

GO
CREATE NONCLUSTERED INDEX [artrxage_ind_4] ON [dbo].[artrxage] ([apply_to_num], [apply_trx_type]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrxage_ind_6] ON [dbo].[artrxage] ([apply_to_num], [apply_trx_type], [ref_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrxage_ind_0] ON [dbo].[artrxage] ([customer_code], [apply_to_num], [apply_trx_type]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_artrxage_ind_7] ON [dbo].[artrxage] ([customer_code], [order_ctrl_num], [date_doc]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrxage_ind_5] ON [dbo].[artrxage] ([doc_ctrl_num], [trx_type], [date_applied]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrxage_ind_2] ON [dbo].[artrxage] ([sub_apply_num], [sub_apply_type], [date_applied]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrxage_ind_3] ON [dbo].[artrxage] ([trx_ctrl_num], [trx_type]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[artrxage] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxage] TO [public]
GO
GRANT REFERENCES ON  [dbo].[artrxage] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxage] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxage] TO [public]
GO
