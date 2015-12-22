SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE proc [dbo].[cc_ins_inv_alerts_defaults_sp]	@number_days 			int = 28,
																					@date_type				smallint = 0,	
																					@create_fu 				smallint = 1,	
																					@create_reminder	smallint = 1,	
																					@recurring				smallint = 1, 



																					@user_id 					int,
																					@all_workloads		smallint = 0,	
																					@workload_code 		varchar(8) = NULL,
																					@auto_run					smallint = 0,
																					@disable_options 	smallint = 0


AS
	SET NOCOUNT ON
	
	IF ( SELECT COUNT(*) FROM cc_alert_defaults WHERE [user_id] = @user_id ) = 0
		INSERT cc_alert_defaults 
		( number_days,
			date_type,
			create_fu,
			create_reminder,
			recurring,
			[user_id],
			all_workloads,
			workload_code,
			auto_run,
			disable_options
		)
		SELECT	@number_days,
						@date_type,
						@create_fu,
						@create_reminder,
						@recurring,
						@user_id,
						@all_workloads,
						@workload_code,
						@auto_run,
						@disable_options 
	ELSE
		UPDATE cc_alert_defaults 
		SET	number_days = @number_days,
				date_type = @date_type,
				create_fu = @create_fu,
				create_reminder = @create_reminder,
				recurring = @recurring,
				all_workloads = @all_workloads,
				workload_code = @workload_code,
				auto_run = @auto_run,
				disable_options = @disable_options
		WHERE [user_id] = @user_id

	IF @@ERROR <> 0 
		RETURN -1
	ELSE
		RETURN 0

GO
GRANT EXECUTE ON  [dbo].[cc_ins_inv_alerts_defaults_sp] TO [public]
GO
