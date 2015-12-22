CREATE TABLE [dbo].[arinpchg_all]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[order_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[date_entered] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[date_shipped] [int] NOT NULL,
[date_required] [int] NOT NULL,
[date_due] [int] NOT NULL,
[date_aging] [int] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fob_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[freight_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fin_chg_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dest_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recurring_flag] [smallint] NOT NULL,
[recurring_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cust_po_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[total_weight] [float] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_tax_included] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_net] [float] NOT NULL,
[amt_paid] [float] NOT NULL,
[amt_due] [float] NOT NULL,
[amt_cost] [float] NOT NULL,
[amt_profit] [float] NOT NULL,
[next_serial_id] [smallint] NOT NULL,
[printed_flag] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[hold_flag] [smallint] NOT NULL,
[hold_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [smallint] NOT NULL,
[customer_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_rem_rev] [float] NOT NULL,
[amt_rem_tax] [float] NOT NULL,
[date_recurring] [int] NOT NULL,
[location_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_type] [smallint] NULL,
[amt_discount_taken] [float] NULL,
[amt_write_off_given] [float] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[edit_list_flag] [smallint] NOT NULL,
[ddid] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[writeoff_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vat_prc] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinpchg___custo__59BA9928] DEFAULT (''),
[customer_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinpchg___custo__5AAEBD61] DEFAULT (''),
[customer_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinpchg___custo__5BA2E19A] DEFAULT (''),
[customer_postal_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinpchg___custo__5C9705D3] DEFAULT (''),
[ship_to_country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinpchg___ship___5D8B2A0C] DEFAULT (''),
[ship_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinpchg___ship___5E7F4E45] DEFAULT (''),
[ship_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinpchg___ship___5F73727E] DEFAULT (''),
[ship_to_postal_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinpchg___ship___606796B7] DEFAULT ('')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[cvo_arinpchg_all_ins_upd_trg]
ON [dbo].[arinpchg_all]
FOR INSERT, UPDATE
AS
BEGIN

	-- DECLARATIONS
	DECLARE	@row_id			int,
			@last_row_id	int,
			@trx_ctrl_num	varchar(16),
			@customer_code	varchar(10),
			@terms_code		varchar(10),
			@date_doc		int,
			@date_due		int

	-- WORKING TABLE
	CREATE TABLE #newrecs (
		row_id			int IDENTITY(1,1),
		trx_ctrl_num	varchar(16),
		customer_code	varchar(10),
		terms_code		varchar(10),
		date_doc		int,
		date_due		int)

	INSERT	#newrecs (trx_ctrl_num, customer_code, terms_code, date_doc, date_due)
	SELECT	trx_ctrl_num, customer_code, terms_code, date_doc, date_due
	FROM	inserted
	WHERE	trx_type = 2031
	AND		LEFT(doc_desc,3) <> 'SO:'
	
	SET @last_row_id = 0

	SELECT TOP 1 @row_id = row_id,
				@trx_ctrl_num = trx_ctrl_num,
				@customer_code = customer_code,
				@terms_code = ISNULL(terms_code,''),
				@date_doc = date_doc,
				@date_due = date_due
	FROM		#newrecs
	WHERE		row_id > @last_row_id
	ORDER BY	row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		EXEC [dbo].[CVO_CalcDueDate_sp]  @customer_code, @date_doc, @date_due OUTPUT, @terms_code

		UPDATE	arinpchg_all
		SET		date_due = @date_due
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND		date_due <> @date_due


		SET @last_row_id = @row_id

		SELECT TOP 1 @row_id = row_id,
					@trx_ctrl_num = trx_ctrl_num,
					@customer_code = customer_code,
					@terms_code = ISNULL(terms_code,''),
					@date_doc = date_doc,
					@date_due = date_due
		FROM		#newrecs
		WHERE		row_id > @last_row_id
		ORDER BY	row_id ASC

	END

	DROP TABLE #newrecs

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--v1.0 TM	02/22/2012	Set the Due Date of the Credits properly based on CVO criteria
  
CREATE TRIGGER [dbo].[CVO_arunpins_tr] ON [dbo].[arinpchg_all] AFTER INSERT, UPDATE
AS   
  
BEGIN
  
DECLARE	@terms_code			varchar(8),
		@trx_ctrl_num		varchar(16),
		@customer_code		varchar(8),
		@order_ctrl_num		varchar(16),
		@date_doc			int,
		@date_due			int,
		@trx_type			int

DECLARE ins_arinp CURSOR LOCAL FOR  
					SELECT i.trx_ctrl_num, i.trx_type, i.date_doc, i.customer_code, c.terms_code, i.order_ctrl_num 
					  FROM inserted i, arcust c
					 WHERE i.customer_code = c.customer_code

OPEN ins_arinp
FETCH NEXT FROM ins_arinp INTO @trx_ctrl_num, @trx_type, @date_doc, @customer_code, @terms_code, @order_ctrl_num

WHILE @@FETCH_STATUS=0
 BEGIN

 IF @trx_type = 2032
    BEGIN
		UPDATE	arinpchg SET apply_to_num = '', apply_trx_type = 0 WHERE trx_ctrl_num = @trx_ctrl_num
    END

 IF @trx_type = 2032 		-- invoice or credit entered direct into AR
    BEGIN
	IF (SELECT COUNT(*) FROM orders_invoice WHERE trx_ctrl_num = @trx_ctrl_num) = 0
		BEGIN
			EXEC dbo.CVO_CalcDueDate_sp @customer_code, @date_doc, @date_due OUTPUT, @terms_code
			UPDATE	arinpchg
			SET		date_due = @date_due,						--, date_aging = @date_due
					apply_to_num = '', apply_trx_type = 0
			WHERE	trx_ctrl_num = @trx_ctrl_num
		END
    END

   FETCH NEXT FROM ins_arinp INTO  @trx_ctrl_num, @trx_type, @date_doc, @customer_code, @terms_code, @order_ctrl_num
 END

END

close ins_arinp
deallocate ins_arinp

GO
CREATE NONCLUSTERED INDEX [arinpchg_all_ind_1] ON [dbo].[arinpchg_all] ([customer_code], [apply_to_num], [date_doc], [trx_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinpchg_all_ind_3] ON [dbo].[arinpchg_all] ([customer_code], [cust_po_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinpchg_all_ind_5] ON [dbo].[arinpchg_all] ([date_applied], [trx_ctrl_num], [trx_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [EAI_Integration] ON [dbo].[arinpchg_all] ([ddid]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinpchg_all_ind_7] ON [dbo].[arinpchg_all] ([doc_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinpchg_all_ind_4] ON [dbo].[arinpchg_all] ([order_ctrl_num], [doc_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinpchg_all_ind_2] ON [dbo].[arinpchg_all] ([price_code], [customer_code], [doc_ctrl_num]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arinpchg_all_ind_0] ON [dbo].[arinpchg_all] ([trx_ctrl_num], [trx_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinpchg_all_ind_6] ON [dbo].[arinpchg_all] ([trx_type], [printed_flag], [hold_flag]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arinpchg_all] TO [public]
GO
GRANT SELECT ON  [dbo].[arinpchg_all] TO [public]
GO
GRANT INSERT ON  [dbo].[arinpchg_all] TO [public]
GO
GRANT DELETE ON  [dbo].[arinpchg_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinpchg_all] TO [public]
GO
