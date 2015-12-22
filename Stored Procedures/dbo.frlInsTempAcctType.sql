SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[frlInsTempAcctType] @UnitNo smallint, @Row_No smallint,
	@pmflag smallint, @negsign smallint, @sequence int, 
	@entity_num smallint, @AcctType smallint
as
begin
	insert #f select @UnitNo , @Row_No, acct_code, @pmflag, @negsign, 
			 acct_group, @sequence, A.acct_id, A.acct_desc, 1
		    from frl_acct_code A
		   where A.entity_num = @entity_num 
		     and A.acct_type = @AcctType
		     and A.rollup_level = 0
		       
end
GO
GRANT EXECUTE ON  [dbo].[frlInsTempAcctType] TO [public]
GO
