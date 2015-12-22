SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[adm_mask_acct] (@account_code varchar(32), @org_id varchar(30))
as
begin
  select dbo.adm_mask_acct_fn (@account_code, @org_id) acct_code
end
GO
GRANT EXECUTE ON  [dbo].[adm_mask_acct] TO [public]
GO
