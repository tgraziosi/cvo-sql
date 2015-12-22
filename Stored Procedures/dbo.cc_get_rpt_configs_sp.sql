SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[cc_get_rpt_configs_sp] @aging_type smallint = 1

AS
	SELECT config_name 
	FROM cc_report_configs
	WHERE aging_type = @aging_type
	ORDER BY config_name

GO
GRANT EXECUTE ON  [dbo].[cc_get_rpt_configs_sp] TO [public]
GO
