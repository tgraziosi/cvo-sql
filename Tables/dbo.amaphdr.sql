CREATE TABLE [dbo].[amaphdr]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[trx_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[doc_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[vendor_code] [dbo].[smVendorCode] NOT NULL,
[apply_date] [dbo].[smApplyDate] NOT NULL,
[ap_posting_code] [dbo].[smPostingCode] NOT NULL,
[nat_currency_code] [dbo].[smCurrencyCode] NOT NULL,
[amt_net] [dbo].[smMoneyZero] NOT NULL,
[completed_flag] [dbo].[smCompletedFlag] NOT NULL,
[completed_date] [dbo].[smApplyDate] NULL,
[completed_by] [dbo].[smUserID] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NULL,
[modified_by] [dbo].[smUserID] NOT NULL,
[org_id] [dbo].[smOrgId] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amaphdr_del_trg] 
ON 				[dbo].[amaphdr] 
FOR 			DELETE 
AS 

DECLARE 
	@result 			smErrorCode





DELETE	amapdet 
FROM	amapdet	det,
		deleted	d
WHERE	d.company_id 	= det.company_id
AND		d.trx_ctrl_num	= det.trx_ctrl_num

SELECT @result = @@error
IF @result <> 0
BEGIN
	ROLLBACK TRANSACTION
	RETURN
END

DELETE	amapchrg 
FROM	amapchrg	ch,
		deleted		d
WHERE	d.company_id 	= ch.company_id
AND		d.trx_ctrl_num	= ch.trx_ctrl_num

SELECT @result = @@error
IF @result <> 0
BEGIN
	ROLLBACK TRANSACTION
	RETURN
END





GO
CREATE UNIQUE CLUSTERED INDEX [amaphdr_ind_0] ON [dbo].[amaphdr] ([company_id], [trx_ctrl_num]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amaphdr].[vendor_code]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amaphdr].[nat_currency_code]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amaphdr].[amt_net]'
GO
EXEC sp_bindrule N'[dbo].[smCompletedFlag_rl]', N'[dbo].[amaphdr].[completed_flag]'
GO
EXEC sp_bindefault N'[dbo].[smCompletedFlag_df]', N'[dbo].[amaphdr].[completed_flag]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amaphdr].[completed_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amaphdr].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amaphdr] TO [public]
GO
GRANT SELECT ON  [dbo].[amaphdr] TO [public]
GO
GRANT INSERT ON  [dbo].[amaphdr] TO [public]
GO
GRANT DELETE ON  [dbo].[amaphdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[amaphdr] TO [public]
GO
