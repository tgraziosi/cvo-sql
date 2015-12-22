SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[frlInsTempAcctSeg] @UnitNo smallint, @Row_No smallint,
	@pmflag smallint, @negsign smallint, @sequence int, 
	@entity_num smallint, @lorange varchar(64), @hirange varchar(64),
	@IsRange tinyint, @fulllike varchar(64), @segno tinyint,
	@rolluplevel tinyint, @AcctType smallint
as
begin
if @AcctType > 0
begin
      insert #f select @UnitNo, @Row_No, B.acct_code, @pmflag, @negsign, 
		       acct_group, @sequence, A.acct_id, A.acct_desc,
		       @rolluplevel + 1
		  from frl_acct_seg B, frl_acct_code A
		 where B.entity_num = @entity_num and B.seg_num = @segno 
		   and B.seg_code like @lorange
		   and B.acct_code like @fulllike 
		   and A.acct_id = B.acct_id 
		   and A.entity_num =  @entity_num 
		   and A.rollup_level = @rolluplevel
		   and A.acct_type = @AcctType
		   
end
else
begin
  if @IsRange = 1
    begin
      insert #f select @UnitNo, @Row_No, B.acct_code, @pmflag, @negsign, 
		       acct_group, @sequence, A.acct_id, A.acct_desc,
		       @rolluplevel + 1
		  from frl_acct_seg B, frl_acct_code A
		 where B.entity_num = @entity_num and B.seg_num = @segno 
		   and B.seg_code between @lorange and @hirange
		   and B.acct_code like @fulllike 
		   and A.acct_id = B.acct_id 
		   and A.entity_num =  @entity_num 
		   and A.rollup_level = @rolluplevel
		   
    end
  else
    begin
      insert #f select @UnitNo, @Row_No, B.acct_code, @pmflag, @negsign, 
		       acct_group, @sequence, A.acct_id, A.acct_desc,
		       @rolluplevel + 1
		  from frl_acct_seg B, frl_acct_code A
		 where B.entity_num = @entity_num and B.seg_num = @segno 
		   and B.seg_code like @lorange
		   and B.acct_code like @fulllike 
		   and A.acct_id = B.acct_id 
		   and A.entity_num =  @entity_num 
		   and A.rollup_level = @rolluplevel
		   
    end
end
end
GO
GRANT EXECUTE ON  [dbo].[frlInsTempAcctSeg] TO [public]
GO
