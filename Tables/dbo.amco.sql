CREATE TABLE [dbo].[amco]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[gl_interface] [dbo].[smLogicalTrue] NOT NULL,
[ap_interface] [dbo].[smLogicalFalse] NOT NULL,
[ar_interface] [dbo].[smLogicalFalse] NOT NULL,
[po_interface] [dbo].[smLogicalFalse] NOT NULL,
[pc_interface] [dbo].[smLogicalFalse] NOT NULL,
[post_depreciation] [dbo].[smLogical] NOT NULL,
[post_additions] [dbo].[smLogical] NOT NULL,
[post_disposals] [dbo].[smLogical] NOT NULL,
[post_other_activities] [dbo].[smLogical] NOT NULL,
[process_id] [dbo].[smSurrogateKey] NOT NULL,
[asset_suspense_acct] [dbo].[smAccountCode] NOT NULL,
[accum_depr_suspense_acct] [dbo].[smAccountCode] NOT NULL,
[revaluation_suspense_acct] [dbo].[smAccountCode] NOT NULL,
[fixed_asset_suspense_acct] [dbo].[smAccountCode] NOT NULL,
[proceeds_suspense_acct] [dbo].[smAccountCode] NOT NULL,
[depr_exp_suspense_acct] [dbo].[smAccountCode] NOT NULL,
[cost_of_rem_suspense_acct] [dbo].[smAccountCode] NOT NULL,
[adjustment_suspense_acct] [dbo].[smAccountCode] NOT NULL,
[gain_loss_suspense_acct] [dbo].[smAccountCode] NOT NULL,
[imm_exp_suspense_acct] [dbo].[smAccountCode] NOT NULL,
[impairment_suspense_acct] [dbo].[smAccountCode] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amco_upd_trg] 
ON 				[dbo].[amco] 
FOR 			UPDATE 
AS 

DECLARE 
	@result			smErrorCode,
	@old_flag		smLogical,
	@new_flag		smLogical,
	@company_id		smCompanyID

 
IF UPDATE(ap_interface)
BEGIN
	
	SELECT 	@company_id		= company_id,
			@new_flag 		= ap_interface 
	FROM 	inserted 	
	
	SELECT	@old_flag		= ap_interface
	FROM	deleted
	WHERE	company_id		= @company_id
	
	IF @old_flag <> @new_flag
	BEGIN
		UPDATE	apco
		SET		am_flag		= @new_flag
		WHERE	company_id	= @company_id

		SELECT	@result = @@error
		IF @result <> 0
		BEGIN
			ROLLBACK TRANSACTION 
			RETURN
		END
	END 

END
GO
CREATE UNIQUE CLUSTERED INDEX [amco_ind_0] ON [dbo].[amco] ([company_id]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amco].[gl_interface]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amco].[gl_interface]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amco].[ap_interface]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amco].[ap_interface]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amco].[ar_interface]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amco].[ar_interface]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amco].[po_interface]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amco].[po_interface]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amco].[pc_interface]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amco].[pc_interface]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amco].[post_depreciation]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amco].[post_additions]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amco].[post_disposals]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amco].[post_other_activities]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amco].[process_id]'
GO
EXEC sp_bindefault N'[dbo].[smTodaysDate_df]', N'[dbo].[amco].[last_modified_date]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amco].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amco] TO [public]
GO
GRANT SELECT ON  [dbo].[amco] TO [public]
GO
GRANT INSERT ON  [dbo].[amco] TO [public]
GO
GRANT DELETE ON  [dbo].[amco] TO [public]
GO
GRANT UPDATE ON  [dbo].[amco] TO [public]
GO
