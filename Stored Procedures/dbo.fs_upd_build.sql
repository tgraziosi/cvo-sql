SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_upd_build] AS
BEGIN

   update what_part set active='A'
   where active='U' and eff_date <= getdate()
   update what_part set active='V'
   where active='B' and eff_date <= getdate()
END

GO
GRANT EXECUTE ON  [dbo].[fs_upd_build] TO [public]
GO
