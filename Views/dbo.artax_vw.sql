SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[artax_vw]
AS

SELECT * FROM artax
WHERE ( tax_connect_flag = ( SELECT tax_connect_flag FROM arco ) OR  tax_connect_flag = 0 )	
GO
GRANT REFERENCES ON  [dbo].[artax_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[artax_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[artax_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[artax_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[artax_vw] TO [public]
GO
