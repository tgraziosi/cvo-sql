SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[tdc_config_vw]
AS

	SELECT	[function] _function,
			mod_owner,
			description,
			active,
			value_str	
	FROM	dbo.tdc_config (NOLOCK)


GO
GRANT SELECT ON  [dbo].[tdc_config_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_config_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_config_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_config_vw] TO [public]
GO
