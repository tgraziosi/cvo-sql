CREATE TABLE [dbo].[artrx_all]
(
[timestamp] [timestamp] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[order_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[date_entered] [int] NOT NULL,
[date_posted] [int] NOT NULL,
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
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_type] [smallint] NOT NULL,
[cust_po_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[non_ar_flag] [smallint] NOT NULL,
[gl_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_trx_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt1_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt2_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt3_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt4_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[deposit_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_tax_included] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_paid_to_date] [float] NOT NULL,
[amt_net] [float] NOT NULL,
[amt_on_acct] [float] NOT NULL,
[amt_cost] [float] NOT NULL,
[amt_tot_chg] [float] NOT NULL,
[user_id] [smallint] NOT NULL,
[void_flag] [smallint] NOT NULL,
[paid_flag] [smallint] NOT NULL,
[date_paid] [int] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[commission_flag] [smallint] NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[non_ar_doc_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[purge_flag] [smallint] NULL,
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
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ddid] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[artrx_cvo_tr] ON [dbo].[artrx_all]
FOR INSERT
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- WORKING TABLE
	CREATE TABLE #cvo_ar_bg_list (
		doc_ctrl_num	varchar(16),
		customer_code	varchar(10),
		parent			varchar(10),
		parent_name		varchar(40))

	-- PROCESSING
	INSERT	#cvo_ar_bg_list
	SELECT	a.doc_ctrl_num, a.customer_code,
			dbo.f_cvo_get_buying_group(a.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, a.date_doc - 693596, '01/01/1900'),121)),
			dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(a.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, a.date_doc - 693596, '01/01/1900'),121)))
	FROM	inserted a 
	WHERE	(a.order_ctrl_num = '' OR LEFT(a.doc_desc,3) NOT IN ('SO:', 'CM:'))  
	AND		a.void_flag <> 1
	AND		dbo.f_cvo_get_buying_group(a.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, a.date_doc - 693596, '01/01/1900'),121)) > '' 

	UPDATE	a
	SET		parent = a.customer_code,
			parent_name = b.customer_name
	FROM	#cvo_ar_bg_list a
	JOIN	arcust b ON a.customer_code = b.customer_code
	WHERE	a.customer_code IN (SELECT parent FROM dbo.cvo_buying_groups_hist (NOLOCK))
	AND		a.parent = ''

	INSERT	dbo.cvo_ar_bg_list (doc_ctrl_num, customer_code, parent, parent_name)
	SELECT	doc_ctrl_num, customer_code, parent, parent_name
	FROM	#cvo_ar_bg_list

	DROP TABLE #cvo_ar_bg_list

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--v1.0 TM	02/22/2012	Set the Due Date of the Credits properly based on CVO criteria
  
CREATE TRIGGER [dbo].[CVO_artrxins_tr] ON [dbo].[artrx_all] AFTER INSERT
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

 IF @trx_type = 2111 AND @doc_ctrl_num like 'CRM%' 		-- invoice or credit entered direct into AR
    BEGIN
		SELECT @date_due = date_due FROM artrx_all WHERE doc_ctrl_num = @doc_ctrl_num AND trx_type = 2032
		UPDATE	artrx_all 
		   SET 	date_due = @date_due, date_aging = @date_due
		 WHERE	trx_ctrl_num = @trx_ctrl_num
    END

   FETCH NEXT FROM ins_arinp INTO  @trx_ctrl_num, @trx_type, @doc_ctrl_num
 END

END

close ins_arinp
deallocate ins_arinp

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE TRIGGER [dbo].[EAI_artrx_ins] ON [dbo].[artrx_all] FOR INSERT
AS
BEGIN
	 DECLARE	@nResult                int, 
		  	@vcInvoice_ID       	varchar(16), 
			@last_Invoice_ID	varchar(16),
		        @Sender         	varchar(32),
			@data 			varchar(32)
	

  if exists(select * from master..sysprocesses 
	      where spid=@@SPID and program_name = 'Epicor EAI')
    return


	IF EXISTS (SELECT a.trx_ctrl_num FROM inserted a, EAI_Invoice_ord_xref b where a.trx_ctrl_num = b.trx_ctrl_num)
	BEGIN		

	 select @last_Invoice_ID = ''
  
	 select @Sender = ddid
	 from smcomp_vw

	  while 1=1
	  BEGIN

	    set rowcount 1

	    select @vcInvoice_ID = a.trx_ctrl_num
	    from inserted a, EAI_Invoice_ord_xref b
	    where a.trx_ctrl_num = b.trx_ctrl_num
	    AND   a.trx_ctrl_num > @last_Invoice_ID
	    order by a.trx_ctrl_num

	    if @@ROWCOUNT <= 0 
	      BREAK
    

    	    set rowcount 0
	    
	    SELECT @data = @vcInvoice_ID + '|0'

	    EXEC EAI_process_insert 'ShippingNotice', @data, 'BO'

	    select @last_Invoice_ID = @vcInvoice_ID

	END/*looping*/

	
	END /*End EAI_Invoice_Ord_XRef Checking*/


END
GO
DISABLE TRIGGER [dbo].[EAI_artrx_ins] ON [dbo].[artrx_all]
GO
CREATE NONCLUSTERED INDEX [artrx_all_ind_5] ON [dbo].[artrx_all] ([apply_to_num], [apply_trx_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrx_all_ind_4] ON [dbo].[artrx_all] ([batch_code], [doc_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cc_po_artrx_ind] ON [dbo].[artrx_all] ([cust_po_num], [customer_code]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [artrx_all_ind_11] ON [dbo].[artrx_all] ([customer_code], [doc_ctrl_num], [trx_ctrl_num], [trx_type]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrx_all_ind_0] ON [dbo].[artrx_all] ([customer_code], [paid_flag], [date_doc], [apply_to_num], [apply_trx_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrx_all_ind_7] ON [dbo].[artrx_all] ([customer_code], [trx_type], [void_flag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrx_all_ind_3] ON [dbo].[artrx_all] ([date_applied], [trx_type]) INCLUDE ([doc_ctrl_num], [doc_desc], [trx_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [EAI_Integration] ON [dbo].[artrx_all] ([ddid]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrx_all_ind_8] ON [dbo].[artrx_all] ([doc_ctrl_num], [trx_type], [paid_flag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_artrx_all_ind_9] ON [dbo].[artrx_all] ([order_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrx_all_ind_10] ON [dbo].[artrx_all] ([process_group_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrx_ind_trx] ON [dbo].[artrx_all] ([trx_ctrl_num]) INCLUDE ([amt_net], [amt_on_acct], [amt_paid_to_date], [date_required]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrx_ind_trx_paid_doc_due] ON [dbo].[artrx_all] ([trx_type], [paid_flag], [doc_ctrl_num], [date_due]) INCLUDE ([customer_code], [order_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrx_all_ind_12_042413] ON [dbo].[artrx_all] ([void_flag], [posted_flag], [trx_type]) INCLUDE ([customer_code], [date_applied], [doc_ctrl_num], [doc_desc], [ship_to_code], [terms_code], [trx_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_void_trx_date] ON [dbo].[artrx_all] ([void_flag], [trx_type], [date_applied]) INCLUDE ([customer_code], [doc_ctrl_num], [doc_desc], [salesperson_code], [ship_to_code], [terms_code], [trx_ctrl_num]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[artrx_all] TO [public]
GO
GRANT INSERT ON  [dbo].[artrx_all] TO [public]
GO
GRANT SELECT ON  [dbo].[artrx_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrx_all] TO [public]
GO
