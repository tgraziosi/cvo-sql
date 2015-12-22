SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


 
 

CREATE PROCEDURE [dbo].[amCancel_sp] 
( 
	@spid 					int,
	@debug_level			smDebugLevel = 0
)
AS
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcancel.sp" + ", line " + STR( 50, 5 ) + " -- ENTRY: "
DECLARE @process_ctrl_num 	varchar(20),
		@result				int
	
IF EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '##amcancel%' AND type = 'U')
BEGIN

	IF EXISTS(SELECT spid	 
 		 FROM ##amcancel
			 WHERE spid = @spid
			 )
	BEGIN 

		IF @debug_level >= 3
			SELECT "Cancel = True"

		BEGIN TRANSACTION

		DELETE ##amcancel
		WHERE spid = @spid

		SELECT * 
		FROM ##amcancel

		IF @@rowcount = 0
			DROP TABLE ##amcancel

		
		SELECT 	@process_ctrl_num 	= p.process_ctrl_num
		FROM 	master..sysprocesses m ,pcontrol_vw p
	 WHERE 	m.login_time 		= p.process_start_date 
		AND 	m.hostprocess 		= p.process_host_id
		AND 	m.spid 				= p.process_server_id 
		AND		m.spid				= @spid
		AND 	p.process_state IN (1,2,4,5) 
		AND 	p.process_parent_app = 10000

		IF @process_ctrl_num IS NOT NULL
		BEGIN
			IF @debug_level >= 3
				SELECT process_canceled = @process_ctrl_num

			UPDATE	pcontrol_vw
			SET		process_server_id 	= 0
			WHERE	process_ctrl_num 	= @process_ctrl_num 

			
		END

		COMMIT TRANSACTION

		SELECT @result = 1
	END
	ELSE 
		SELECT @result = 0
END
ELSE
	SELECT @result = 0

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcancel.sp" + ", line " + STR( 109, 5 ) + " -- EXIT: "
RETURN @result


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[amCancel_sp] TO [public]
GO
