SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		ELABARBERA
-- Create date: 4/16/2013
-- Description:	Insert into Open Pick Comments 
-- exec cvo_OpenPickComments_insert_sp '9999991','0','THIS IS A TEST FROM ELIZABETH'
-- =============================================
CREATE PROCEDURE [dbo].[cvo_OpenPickComments_insert_sp] 

@order_no int,
@order_ext int,
@Comments varchar(255)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    
	IF EXISTS (select ORDER_NO from cvo_OpenPickRptComments where order_no=@order_no and order_ext=@order_ext)
BEGIN
			delete from cvo_OpenPickRptComments where order_no=@order_no and order_ext=@order_ext
			insert into cvo_OpenPickRptComments VALUES (@order_no,@order_ext,@Comments)
END
	ELSE
			insert into cvo_OpenPickRptComments VALUES (@order_no,@order_ext,@Comments)

END


GO
