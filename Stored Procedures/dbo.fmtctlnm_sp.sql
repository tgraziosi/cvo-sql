SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\fmtctlnm.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[fmtctlnm_sp]
	@num		int,
	@mask_str	varchar(16),
	@ctrl_num 	varchar(16) OUTPUT,
	@error_flag 	smallint OUTPUT
	
AS

DECLARE	@maskp		varchar(16),
	@num_str	varchar(16),
	@nump		varchar(16),
	@pos_str	varchar(2),
	@start_pos	smallint,
	@cur_pos	smallint,
	@mask_len	smallint,
	@mask_lenp	smallint,
	@num_len	smallint
	
	

SELECT	@maskp	 = ' ',
	@num_str = ' ',
	@nump	 = ' ',
	@start_pos = 0,
	@cur_pos = 0,
	@mask_len = 0,
	@mask_lenp = 0,
	@num_len = 0
 
	
	SELECT @num_str = CONVERT(varchar(16), @num)

	
	SELECT @mask_len = DATALENGTH(@mask_str),
	 @num_len = DATALENGTH(@num_str),
		@nump = REVERSE(@num_str)

	
	SELECT @cur_pos = 1


	WHILE ( @cur_pos <= @mask_len)
 	BEGIN
		SELECT @pos_str = SUBSTRING(@mask_str, @cur_pos, 1)

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
		SELECT @error_flag = -20
		RETURN
	END
	

	SELECT @maskp = REVERSE(SUBSTRING(@mask_str,@start_pos, @mask_lenp))

	SELECT @num_str = REVERSE( @num_str)


	SELECT @cur_pos = 1

	
	WHILE ( @cur_pos <=@mask_lenp )
	BEGIN

		IF @cur_pos = 1
			SELECT @nump = SUBSTRING(@num_str, @cur_pos, 1)
		ELSE
		
		IF @cur_pos > @num_len
		BEGIN

			IF SUBSTRING(@maskp, @cur_pos, 1) = '0'
				SELECT @nump = @nump + '0'
		END
		ELSE
			SELECT @nump = @nump + SUBSTRING(@num_str, @cur_pos, 1)

		SELECT @cur_pos = @cur_pos + 1
	END

	
	SELECT @nump = REVERSE( @nump)

	
	SELECT @ctrl_num = stuff(@mask_str, @start_pos, @mask_lenp, @nump),
	 @error_flag = 0


	RETURN



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[fmtctlnm_sp] TO [public]
GO
