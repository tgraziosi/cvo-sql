SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[imerrxref_vw]
AS
    SELECT imtable,
       error_name,
       error_message,
       error_bit,
       status_field,
	   record_id_num
  FROM CVO_Control.dbo.imerrxref



GO
GRANT REFERENCES ON  [dbo].[imerrxref_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imerrxref_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imerrxref_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imerrxref_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imerrxref_vw] TO [public]
GO
