SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[frlInsTempAcctCode] @UnitNo smallint, @Row_No smallint,
	@pmflag smallint, @negsign smallint, @sequence int, 
	@entity_num smallint, @lorange varchar(64), @hirange varchar(64),
	@IsNat tinyint, @IsRange tinyint, @fulllike varchar(64),
	@rolluplevel tinyint, @AcctType smallint

as
begin
if @AcctType = 0
begin
  if @IsNat = 0
    begin
      if @IsRange = 0
	begin
	  insert #f select @UnitNo , @Row_No, acct_code, @pmflag, @negsign, 
			   acct_group, @sequence, A.acct_id, A.acct_desc,
			   @rolluplevel + 1
		      from frl_acct_code A
		     where A.entity_num = @entity_num 
		       and A.acct_code like @lorange 
		       and A.rollup_level = @rolluplevel
		       
	end
      else
	begin
	  insert #f select @UnitNo , @Row_No, acct_code, @pmflag, @negsign, 
			   acct_group, @sequence, A.acct_id, A.acct_desc,
			   @rolluplevel + 1
		      from frl_acct_code A
		     where A.entity_num = @entity_num 
		       and A.acct_code between @lorange and @hirange
		       and A.acct_code like @fulllike   
		       and A.rollup_level = @rolluplevel
			   
	end
    end
  else
    begin
      if @IsRange = 0
	begin
	  insert #f select @UnitNo , @Row_No, acct_code, @pmflag, @negsign, 
			   acct_group, @sequence, A.acct_id, A.acct_desc,
			   @rolluplevel + 1
		      from frl_acct_code A
		     where A.entity_num = @entity_num 
		       and A.nat_seg_code like @lorange 
		       and A.rollup_level = @rolluplevel
			
	end
      else
	begin
	  insert #f select @UnitNo , @Row_No, acct_code, @pmflag, @negsign, 
			   acct_group, @sequence, A.acct_id, A.acct_desc,
			   @rolluplevel + 1
		      from frl_acct_code A
		     where A.entity_num = @entity_num 
		       and A.nat_seg_code between @lorange  and @hirange
		       and A.acct_code like @fulllike
		       and A.rollup_level = @rolluplevel
		       
	end
    end
end
else
begin
  if @IsNat = 0
    begin
	  insert #f select @UnitNo , @Row_No, acct_code, @pmflag, @negsign, 
			   acct_group, @sequence, A.acct_id, A.acct_desc,
			   @rolluplevel + 1
		      from frl_acct_code A
		     where A.entity_num = @entity_num 
		       and A.acct_code like @lorange 
		       and A.rollup_level = @rolluplevel
		       and A.acct_type = @AcctType
		       
    end
  else
    begin
	  insert #f select @UnitNo , @Row_No, acct_code, @pmflag, @negsign, 
			   acct_group, @sequence, A.acct_id, A.acct_desc,
			   @rolluplevel + 1
		      from frl_acct_code A
		     where A.entity_num = @entity_num 
		       and A.nat_seg_code like @lorange 
		       and A.rollup_level = @rolluplevel
		       and A.acct_type = @AcctType
			
    end
end

end
GO
GRANT EXECUTE ON  [dbo].[frlInsTempAcctCode] TO [public]
GO
