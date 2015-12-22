SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		ELABARBERA
-- Create date: 6/23/2014
-- Description:	Inserts Orders to be listed on DC Dashboard
-- EXEC cvo_DC_RetailDashboard_sp 1,1,'1/1/2014','Elizabeth LaBarbera'
-- select * from cvo_DC_RetailDashboard
-- =============================================
CREATE PROCEDURE [dbo].[cvo_DC_RetailDashboard_sp] 

@order_no varchar(10),
@SpecialPackaging bit,
@KA_DueDate datetime,
@KA_Agent varchar(30)

AS

IF  ISNULL((select order_no from cvo_DC_RetailDashboard where order_no=@order_no),0) <> @order_no
	BEGIN
	SET NOCOUNT ON;
	insert into cvo_DC_RetailDashboard (entered_date, order_no, SpecialPackaging, KA_DueDate, KA_Agent) VALUES (getdate(),@order_no,@SpecialPackaging, @KA_DueDate,@KA_Agent)
	END


GO
