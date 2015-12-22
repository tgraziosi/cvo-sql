SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_TPS_installed]

AS

 select count(*) from CVO_Control..dminfo where property_id = 53000

GO
GRANT EXECUTE ON  [dbo].[cc_TPS_installed] TO [public]
GO
