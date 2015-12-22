SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[cc_delete_rpt_config_sp] @config_name	varchar(65),
												@aging_type		smallint

AS
	IF (SELECT COUNT(*) FROM cc_report_configs WHERE config_name = @config_name) > 0
		DELETE cc_report_configs WHERE config_name = @config_name
		AND	aging_type = @aging_type


GO
GRANT EXECUTE ON  [dbo].[cc_delete_rpt_config_sp] TO [public]
GO
