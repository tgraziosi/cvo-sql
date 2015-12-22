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
GRANT REFERENCES ON  [dbo].[artrxage] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxage] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxage] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxage] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxage] TO [public]
GO
