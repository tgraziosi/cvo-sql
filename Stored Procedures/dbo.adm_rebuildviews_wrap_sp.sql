SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[adm_rebuildviews_wrap_sp]
AS

exec adm_rebuildviews_sp

select 1
GO
GRANT EXECUTE ON  [dbo].[adm_rebuildviews_wrap_sp] TO [public]
GO
