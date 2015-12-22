SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		ELABARBERA
-- Create date: 4/2/2013
-- Description:	Insert into BB
-- exec cvo_bbcusts_insert_sp 2013, 000010, 000010, 10000,5,11000,6,12000,7
-- exec cvo_bbcusts_insert_sp 2013, 000010, 000010, 10000,5
-- =============================================
CREATE PROCEDURE [dbo].[cvo_bbcusts_insert_sp] 

@progyear varchar(5),
@master_cust_code varchar(8),
@cust_code varchar(8),
@goal1 decimal(20,8),
@rebatepct1 decimal(20,8),
@goal2 decimal(20,8) = NULL,
@rebatepct2 decimal(20,8) = NULL,
@goal3 decimal(20,8) = NULL,
@rebatepct3 decimal(20,8) = NULL

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	insert into cvo_businessbuildercusts VALUES (@progyear,@master_cust_code,@cust_code,@goal1,@rebatepct1,@goal2,@rebatepct2,@goal3,@rebatepct3)
END
GO
