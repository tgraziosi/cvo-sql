SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[aeg_error_vw] as
SELECT appid,
       langid,
       error_code,
       active,
       elevel,
       text
  FROM CVO_Control.dbo.aeg_error



GO
GRANT REFERENCES ON  [dbo].[aeg_error_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[aeg_error_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[aeg_error_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[aeg_error_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[aeg_error_vw] TO [public]
GO
