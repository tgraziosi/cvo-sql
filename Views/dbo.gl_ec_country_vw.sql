SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[gl_ec_country_vw]
AS

SELECT * FROM gl_country WHERE ec_member = 1
GO
GRANT REFERENCES ON  [dbo].[gl_ec_country_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_ec_country_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_ec_country_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_ec_country_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_ec_country_vw] TO [public]
GO
