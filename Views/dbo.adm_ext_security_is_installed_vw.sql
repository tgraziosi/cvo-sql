SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[adm_ext_security_is_installed_vw]
		AS select -1 sec_level
GO
GRANT SELECT ON  [dbo].[adm_ext_security_is_installed_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_ext_security_is_installed_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_ext_security_is_installed_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_ext_security_is_installed_vw] TO [public]
GO
