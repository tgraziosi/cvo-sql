SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[fvi_smuserperm_vw]
as
	-- replace control database name here
	select * from CVO_Control..smuserperm
GO
