SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_log_types_select]

AS
select short_desc, description, log_type from cc_log_types order by log_type


GO
GRANT EXECUTE ON  [dbo].[cc_log_types_select] TO [public]
GO
