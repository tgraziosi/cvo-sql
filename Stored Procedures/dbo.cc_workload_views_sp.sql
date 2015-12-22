SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_workload_views_sp]
AS
	select name from sysobjects where type = 'V' and name like 'ccu%'
GO
GRANT EXECUTE ON  [dbo].[cc_workload_views_sp] TO [public]
GO
