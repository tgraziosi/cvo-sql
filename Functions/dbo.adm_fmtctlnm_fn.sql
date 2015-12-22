SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[adm_fmtctlnm_fn] (@tcn int, @tcn_mask varchar(16))
RETURNS varchar(16)
BEGIN		
  declare @ctrl_num 	varchar(16),
    @error_flag 	smallint

DECLARE	@maskp		varchar(16),
	@tcn_str	varchar(16),
	@nump		varchar(16),
	@pos_str	varchar(2),
	@start_pos	smallint,
	@cur_pos	smallint,
	@mask_len	smallint,
	@mask_lenp	smallint,
	@num_len	smallint
	
	

SELECT	@maskp	 = ' ',
	@tcn_str = ' ',
	@nump	 = ' ',
	@start_pos = 0,
	@cur_pos = 0,
	@mask_len = 0,
	@mask_lenp = 0,
	@num_len = 0
 
	
	SELECT @tcn_str = CONVERT(varchar(16), @tcn)

	
	SELECT @mask_len = DATALENGTH(@tcn_mask),
	 @num_len = DATALENGTH(@tcn_str),
		@nump = REVERSE(@tcn_str)

	
	SELECT @cur_pos = 1


	WHILE ( @cur_pos <= @mask_len)
 	BEGIN
		SELECT @pos_str = SUBSTRING(@tcn_mask, @cur_pos, 1)

		IF @start_pos = 0
		BEGIN
			IF @pos_str = '0' OR @pos_str = '#'
				SELECT @start_pos = @cur_pos, @mask_lenp = 1
		END
		ELSE
		BEGIN
			IF @pos_str != '0' AND @pos_str != '#'
				BREAK

			SELECT @mask_lenp = @mask_lenp + 1
		END

		SELECT @cur_pos = @cur_pos + 1
	END

	
	IF @mask_lenp < @num_len
	BEGIN
		select @ctrl_num = '!ERROR!'
		RETURN @ctrl_num
	END
	

	SELECT @maskp = REVERSE(SUBSTRING(@tcn_mask,@start_pos, @mask_lenp))

	SELECT @tcn_str = REVERSE( @tcn_str)


	SELECT @cur_pos = 1

	
	WHILE ( @cur_pos <=@mask_lenp )
	BEGIN

		IF @cur_pos = 1
			SELECT @nump = SUBSTRING(@tcn_str, @cur_pos, 1)
		ELSE
		
		IF @cur_pos > @num_len
		BEGIN

			IF SUBSTRING(@maskp, @cur_pos, 1) = '0'
				SELECT @nump = @nump + '0'
		END
		ELSE
			SELECT @nump = @nump + SUBSTRING(@tcn_str, @cur_pos, 1)

		SELECT @cur_pos = @cur_pos + 1
	END

	
	SELECT @nump = REVERSE( @nump)

	
	SELECT @ctrl_num = stuff(@tcn_mask, @start_pos, @mask_lenp, @nump),
	 @error_flag = 0

  return @ctrl_num
END
GO
GRANT REFERENCES ON  [dbo].[adm_fmtctlnm_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[adm_fmtctlnm_fn] TO [public]
GO
