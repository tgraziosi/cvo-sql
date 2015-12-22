SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[aptax_vw]
AS

SELECT * FROM aptax
WHERE ( tax_connect_flag = ( SELECT tax_connect_flag FROM apco ) OR  tax_connect_flag = 0 )	
GO
GRANT REFERENCES ON  [dbo].[aptax_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[aptax_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[aptax_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[aptax_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptax_vw] TO [public]
GO
