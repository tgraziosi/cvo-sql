SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[adm_mask_acct_fn] (@account_code varchar(32), @org_id varchar(30))
RETURNS varchar(32)
as
begin
	DECLARE @new_account varchar(32),	@branch_account_number varchar(32),		@seg1 varchar(32),		
		@seg2 varchar(32),		@seg3 varchar(32),				@seg4 varchar(32),
                @ib_flag int, 			@ib_segment int,				@ib_offset int,
		@ib_length int
	
	select @ib_flag = ib_flag, @ib_segment = ib_segment, @ib_offset = ib_offset, @ib_length = ib_length from glco (nolock)

	IF @ib_flag <> 1
	BEGIN
		SELECT @new_account = @account_code
	END
	ELSE
	BEGIN	
		SELECT 	@branch_account_number = branch_account_number
		FROM	Organization_all (nolock)
		WHERE	organization_id = @org_id

                select @seg1 = seg1_code, @seg2 = seg2_code, @seg3 = seg3_code, @seg4 = seg4_code
                from glchart coa (nolock)
                where account_code = @account_code
		
                if @ib_flag = 1
                begin 
                  if @org_id = '' or @branch_account_number = ''
                    select @seg1 = '', @seg2 = '', @seg3 = '', @seg4 = ''
                  else
                  begin
  		    if @ib_segment = 1 SELECT @seg1 = STUFF(@seg1,@ib_offset,@ib_length,@branch_account_number)
		    if @ib_segment = 2 SELECT @seg2 = STUFF(@seg2,@ib_offset,@ib_length,@branch_account_number)
		    if @ib_segment = 3 SELECT @seg3 = STUFF(@seg3,@ib_offset,@ib_length,@branch_account_number)
		    if @ib_segment = 4 SELECT @seg4 = STUFF(@seg4,@ib_offset,@ib_length,@branch_account_number)
                  end
                end
		
		SELECT @new_account = @seg1 + @seg2 + @seg3 + @seg4 
	END
	RETURN ISNULL(@new_account,'')
end
GO
GRANT REFERENCES ON  [dbo].[adm_mask_acct_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[adm_mask_acct_fn] TO [public]
GO
