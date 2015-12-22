SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_TPS_info]

AS

 select int_value, char_value from CVO_Control..dminfo where property_id = 53000

GO
GRANT EXECUTE ON  [dbo].[cc_TPS_info] TO [public]
GO
