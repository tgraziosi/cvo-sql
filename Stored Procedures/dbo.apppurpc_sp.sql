SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[apppurpc_sp]	@purge_through_date		int,
				@result			smallint OUTPUT
AS
BEGIN

	SELECT @result = 1

	DELETE pbatch
	FROM	pcontrol_vw p
	WHERE	p.process_ctrl_num = pbatch.process_ctrl_num
	AND	p.process_state = 3
	AND	datediff(dd,"1/1/1800",ISNULL(p.process_end_date,"1/1/1800")) + 657072 <= @purge_through_date
	IF( @@error != 0 )
	BEGIN
		SELECT @result = 0
		RETURN
	END
	
	DELETE perror
	FROM	pcontrol_vw p
	WHERE	p.process_ctrl_num = perror.process_ctrl_num
	AND	p.process_state = 3
	AND	datediff(dd,"1/1/1800",ISNULL(p.process_end_date,"1/1/1800")) + 657072 <= @purge_through_date
	IF( @@error != 0 )
	BEGIN
		SELECT @result = 0
		RETURN
	END

	DELETE batchctl
	WHERE	posted_flag = 1
	AND	date_posted <= @purge_through_date
	IF( @@error != 0 )
	BEGIN
		SELECT @result = 0
		RETURN
	END

	RETURN @result
	
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apppurpc_sp] TO [public]
GO
