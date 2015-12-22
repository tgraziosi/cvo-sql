SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_varchar_to_ts_sp] @ts_vc varchar(20), @ts timestamp Output as
BEGIN		
  declare @stmt nvarchar(200)

  select @stmt = N'Select @ts = ' + @ts_vc
  exec sp_executesql @stmt, N'@ts timestamp output', @ts output

END
GO
GRANT EXECUTE ON  [dbo].[adm_varchar_to_ts_sp] TO [public]
GO
