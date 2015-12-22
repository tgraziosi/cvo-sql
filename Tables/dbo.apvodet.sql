CREATE TABLE [dbo].[apvodet]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_ordered] [float] NOT NULL,
[qty_received] [float] NOT NULL,
[qty_returned] [float] NOT NULL,
[code_1099] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_price] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_misc] [float] NOT NULL,
[amt_extended] [float] NOT NULL,
[calc_tax] [float] NOT NULL,
[gl_exp_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_id] [int] NOT NULL,
[rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_orig_flag] [smallint] NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_nonrecoverable_tax] [float] NULL,
[amt_tax_det] [float] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[CVO_COOP_Redemption_tr] on [dbo].[apvodet]
   FOR INSERT
AS

DECLARE @s_coop_acct		varchar(32),
		@i_ref_code			varchar(32),
		@i_account			varchar(32),
		@i_amt_redeemed		Decimal(20,8)

SELECT @s_coop_acct = value_str FROM config WHERE flag = 'COOP_ACCOUNT'

DECLARE coop_cursor CURSOR LOCAL FOR 
		SELECT i.reference_code, i.gl_exp_acct, i.amt_extended FROM inserted i

OPEN coop_cursor
FETCH NEXT FROM coop_cursor INTO @i_ref_code, @i_account, @i_amt_redeemed

WHILE @@FETCH_STATUS=0
BEGIN
	IF @i_account = @s_coop_acct
		BEGIN
			UPDATE cvo_armaster_all Set coop_redeemed = coop_redeemed + @i_amt_redeemed 
				WHERE customer_code = @i_ref_code
		END

	FETCH NEXT FROM coop_cursor INTO @i_ref_code, @i_account, @i_amt_redeemed
END

CLOSE coop_cursor
DEALLOCATE coop_cursor

GO
CREATE UNIQUE CLUSTERED INDEX [apvodet_ind_0] ON [dbo].[apvodet] ([trx_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apvodet] TO [public]
GO
GRANT SELECT ON  [dbo].[apvodet] TO [public]
GO
GRANT INSERT ON  [dbo].[apvodet] TO [public]
GO
GRANT DELETE ON  [dbo].[apvodet] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvodet] TO [public]
GO
