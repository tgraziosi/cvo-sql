SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ARCreateBatchBlock_SP]	@user_id	smallint,
					@debug_level	smallint = 0
AS
BEGIN
DECLARE	@result        	int,
	@tran_started		smallint,
	@sequence_key		int,
	@masked		varchar( 35 ),
	@mask			varchar( 35 ),
	@maskp			varchar( 35 ),
	@maskheader			varchar( 35 ),
	@maskcontent			varchar( 35 ),
	@maskchar	char,
	@maskzero	int,
	@maskmid	int,
	@maskflag	int,
	@maskpl int,
	@num			int,
	@snum		int,
	@num2031			int,
	@num2032			int,
	@num_type		int,
	@zeros			int,
	@pounds		int,
	@masklength	int,
	@cur_num	int,
	@trunc_table	smallint,
	@cnt int,
	@next_bat_num int,
	@batch_description      varchar(30),
	@jul_date               int,
	@jul_time               int,          
	@doc_name               char(30),
	@user_name              varchar(30),
	@bat_count int,
	@company_code			varchar(30)


	EXEC appgetstring_sp 'STR_STD_TRANS', @doc_name OUT

	SELECT @user_name=user_name
	FROM ewusers_vw
	WHERE user_id = @user_id
	


	EXEC appdate_sp @jul_date output
	EXEC apptime_sp @jul_time output 

	SELECT	@bat_count = count(*)
	FROM	#arbatnum

	IF ( @@trancount = 0 )
	BEGIN
		BEGIN TRANSACTION
		SELECT  @tran_started = 1
	END

	UPDATE	ewnumber
	SET	fill1 = ' '
	WHERE	num_type = 2100

	SELECT	@next_bat_num = next_num 
	FROM	ewnumber
	WHERE	num_type = 2100

	UPDATE	ewnumber
	SET	next_num = @bat_count + @next_bat_num
	WHERE	num_type = 2100

	






	SELECT	@mask = RTRIM(mask)
	FROM	ewnumber
	WHERE	num_type = 2100

	IF ( @tran_started = 1 )
	BEGIN
		COMMIT TRANSACTION
		SELECT  @tran_started = 0
	END

	UPDATE	#arbatnum
	SET		batch_description = bat.batch_description
	FROM	batchctl bat
	WHERE	#arbatnum.process_group_num = bat.process_group_num

	SELECT	@maskflag = SIGN(CHARINDEX("0", @mask)) + SIGN(CHARINDEX("#", @mask))

	IF @maskflag = 1
	BEGIN

		



		SELECT @maskzero = SIGN(CHARINDEX("0", @mask))
		IF @maskzero = 1
			SELECT	@maskchar = "0"
		ELSE
			SELECT	@maskchar = "#"

		


		SELECT	@maskp = REVERSE(@mask)

		SELECT	@maskpl = DATALENGTH(@maskp)

		WHILE SUBSTRING(@maskp, 1, 1) = @maskchar
		BEGIN
			SELECT	@maskp = SUBSTRING(@maskp, 2, @maskpl - 1)

			SELECT	@maskpl = DATALENGTH(@maskp)

		END

		SELECT	@maskheader = REVERSE(@maskp),
			@maskcontent = SUBSTRING(@mask, @maskpl + 1, DATALENGTH(@mask)-@maskpl)
		






		UPDATE	#arbatnum
		SET	batch_ctrl_num = @maskheader +
				substring( @maskcontent, 1 * @maskzero, datalength(@maskcontent) -
				datalength(ltrim(str(#arbatnum.seq + @next_bat_num - 1)))) +
				ltrim(str(#arbatnum.seq + @next_bat_num - 1)),
			flag = 1

	END
	ELSE
	BEGIN

		





		SELECT @sequence_key = 1

		WHILE( 1=1 )
		BEGIN

			SELECT	@num = seq + @next_bat_num - 1
			FROM	#arbatnum
			WHERE	@sequence_key = seq

			IF( @@rowcount = 0 )
				BREAK

			EXEC fmtctlnm_sp	@num,
						@mask,
						@masked output,
						@result output

			UPDATE	#arbatnum
			SET	batch_ctrl_num = @masked,
				flag = 1
			WHERE	@sequence_key = seq

			SELECT	@sequence_key = @sequence_key + 1

		END
	END

	UPDATE	#arbatnum
	SET	flag = 0
	FROM	batchctl
	WHERE	#arbatnum.batch_ctrl_num = batchctl.batch_ctrl_num

	SELECT	@company_code = company_code
	FROM	glco

	INSERT into batchctl
	(
		batch_ctrl_num,		batch_description,	start_date,
		start_time,		completed_date,		completed_time,
		control_number,		control_total,		actual_number,
		actual_total,
		batch_type,
		document_name,
		hold_flag,		posted_flag,		void_flag,
		selected_flag,		number_held,		date_applied,
		date_posted,		time_posted,		start_user,
		completed_user,		posted_user,		company_code,
		org_id	
	)
	SELECT	batch_ctrl_num,	ISNULL(batch_description, @doc_name),	@jul_date,
		@jul_time,		0,			0,
		0,			0.0,			0,
		0.0,
		2010 * sign(sign(trx_type - 2031) + 1) * abs(sign(trx_type - 2051)) * abs(sign(trx_type - 2032)) +
			2040 * abs(sign(trx_type - 2031)) * sign(sign(trx_type - 2051) + 1) *
			abs(sign(trx_type - 2032)) + 2030 * abs(sign(trx_type - 2031)) *
			abs(sign(trx_type - 2051)) * sign(sign(trx_type - 2032) + 1),
		@doc_name,
		0,			0,			0,
		0,			0,			date_applied,
		0,			0,			@user_name,
		" ",			" ",			@company_code,
		org_id  
	FROM	#arbatnum
	WHERE	flag = 1

END
GO
GRANT EXECUTE ON  [dbo].[ARCreateBatchBlock_SP] TO [public]
GO
