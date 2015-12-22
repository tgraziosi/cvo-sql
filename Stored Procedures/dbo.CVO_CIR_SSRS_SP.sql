SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tine Graziosi	
-- Create date: 06/28/2012
-- Description:	CVO CIR for SSRS
-- exec cvo_cir_ssrs_sp 'CVOPTICAL\sstrohman'
-- =============================================
CREATE PROCEDURE [dbo].[CVO_CIR_SSRS_SP] @User varchar(1024) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @terr varchar(1024)

    -- Insert statements for procedure here
	set @terr = (select territory_code from cvo_territoryxref where User_name = @user)
--	select @terr
	select * from cvo_carbi where territory = @terr

END
GO
