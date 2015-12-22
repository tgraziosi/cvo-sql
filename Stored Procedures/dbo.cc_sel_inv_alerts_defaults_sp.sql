SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE proc [dbo].[cc_sel_inv_alerts_defaults_sp]	@type smallint = 0,
																					@text varchar(45) = ''


AS
	SET NOCOUNT ON

	IF ( @type = 0 )
		BEGIN
			IF ( SELECT COUNT(*) FROM cc_alert_defaults WHERE [user_id] = @text ) > 0
				BEGIN
					SELECT	number_days,
									date_type,
									create_fu,
									create_reminder,
									recurring,
									a.[user_id],
									[user_name],
									all_workloads,
									workload_code,
									auto_run,
									disable_options	
					FROM	cc_alert_defaults a, CVO_Control..smusers s
					WHERE	a.[user_id] = @text
					AND		a.[user_id] = s.[user_id]
				END
			ELSE
				BEGIN
					SELECT 0, 0, 0, 0, 0, @text, [user_name], 0, '', 0, 0 
					FROM	CVO_Control..smusers
					WHERE	[user_id] = @text
				END
		END
	ELSE
		BEGIN
			IF ( 	SELECT COUNT(*) 
						FROM cc_alert_defaults a, CVO_Control..smusers s 
						WHERE	s.[user_name] = @text
						AND		a.[user_id] = s.[user_id] ) > 0
				BEGIN
					SELECT	number_days,
									date_type,
									create_fu,
									create_reminder,
									recurring,
									a.[user_id],
									[user_name],
									all_workloads,
									workload_code,
									auto_run,
									disable_options	
					FROM	cc_alert_defaults a, CVO_Control..smusers s
					WHERE	s.[user_name] = @text
					AND		a.[user_id] = s.[user_id]
				END
			ELSE
				BEGIN
					SELECT 0, 0, 0, 0, 0, [user_id], @text, 0, '', 0, 0 
					FROM	CVO_Control..smusers
					WHERE	[user_name] = @text
				END
		END

GO
GRANT EXECUTE ON  [dbo].[cc_sel_inv_alerts_defaults_sp] TO [public]
GO
